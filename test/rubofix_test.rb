# frozen_string_literal: true
require_relative "test_helper"

SingleCov.covered!

describe Rubofix do
  it "has a VERSION" do
    Rubofix::VERSION.must_match /^[.\da-z]+$/
  end

  describe "#fix!" do
    def call(offense)
      capture_stdout do
        Tempfile.create("test") do |f|
          File.write(f, "a\nb\nc")
          rubofix.stubs(:send_to_openai).returns("x")
          rubofix.fix!(format(offense, path: f.path))
          File.read(f).must_equal "a\nx\nc"
        end
      end
    end

    let(:rubofix) { Rubofix.new(api_key: "x", model: "x", context: 0) }

    it "fixes" do
      call("%<path>s:2:1: this is bad!").must_match /\AFixing.*\nx\n\z/
    end

    it "prints debug info" do
      with_env DEBUG: "1" do
        call("%<path>s:2:1: this is bad!").must_include "prompt"
      end
    end

    it "fails on unreadable offense" do
      e = assert_raises(RuntimeError) { call("this is bad!") }
      e.message.must_include "unable to parse offense"
    end
  end

  describe "#lines_from_file" do
    def call(context)
      Rubofix.new(api_key: "x", model: "x", context: context).send(:lines_from_file, "MIT-LICENSE", 5)
    end

    it "finds single line" do
      call(0).must_equal [
        "\"Software\"), to deal in the Software without restriction, including",
        ["line     5:\"Software\"), to deal in the Software without restriction, including"]
      ]
    end

    it "can add context" do
      call(1).must_equal [
        "\"Software\"), to deal in the Software without restriction, including",
        [
          "line     4:a copy of this software and associated documentation files (the",
          "line     5:\"Software\"), to deal in the Software without restriction, including",
          "line     6:without limitation the rights to use, copy, modify, merge, publish,"
        ]
      ]
    end

    it "does not crash when context is too large" do
      call(100)[1].size.must_equal 21
    end
  end

  describe "#replace_line_in_file" do
    def call(...)
      Rubofix.new(api_key: "x", model: "x", context: 0).send(:replace_line_in_file, ...)
    end

    it "replaces a line" do
      Tempfile.create("test") do |path|
        File.write(path, "a\nb\nc")
        call(path, 2, "x")
        File.read(path).must_equal "a\nx\nc"
      end
    end

    it "leaves extra newlines alone" do
      Tempfile.create("test") do |path|
        File.write(path, "\n\n\n\n\n\n\n")
        call(path, 2, "x")
        File.read(path).must_equal "\nx\n\n\n\n\n\n"
      end
    end
  end

  describe "#send_to_openai" do
    def call
      Rubofix.new(api_key: "x", model: "x", context: 0).send(:send_to_openai, "hi")
    end

    it "sends" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with(headers: { 'Authorization' => 'Bearer x' })
        .to_return(body: { choices: [{ message: { content: "ho" } }] }.to_json)
      call.must_equal "ho"
    end

    it "fails on error" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 400)
      e = assert_raises(RuntimeError) { call }
      e.message.must_include "Invalid http response 400"
    end
  end
end
