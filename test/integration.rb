# frozen_string_literal: true

# test that need api key set and might not be deterministic

require_relative "test_helper"

describe "integration" do
  it "can fix assignment" do
    Tempfile.create("test.rb") do |f|
      File.write f.path, <<~RUBY
        if a = 1
          puts a
        end
      RUBY
      assert system("bin/rubofix #{f.path}")
      File.read(f.path).must_equal <<~RUBY
        # frozen_string_literal: true

        if (a = 1)
          puts a
        end
      RUBY
    end
  end
end
