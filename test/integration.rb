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

  it "can fix Gemspec/DevelopmentDependencies" do
    Dir.mktmpdir "test" do |dir|
      Dir.chdir(dir) do
        File.write(".rubocop.yml", <<~YAML)
          AllCops:
            NewCops: enable
            TargetRubyVersion: 3.0
        YAML
        File.write("foo.gemspec", <<~RUBY)
          # frozen_string_literal: true

          Gem::Specification.new 'foo', 'v1' do |s|
            s.required_ruby_version = '>= 2.7'
            s.add_development_dependency 'bundler', '>= 1.3'
          end
        RUBY
        File.write("Gemfile", <<~RUBY)
          source "https://rubygems.org"
          gem "bar"
          gemspec
        RUBY
        assert system("#{Bundler.root}/bin/rubofix foo.gemspec")
        File.read("foo.gemspec").must_equal <<~RUBY
          # frozen_string_literal: true

          Gem::Specification.new 'foo', 'v1' do |s|
            s.required_ruby_version = '>= 2.7'
          end
        RUBY
        File.read("Gemfile").must_equal <<~RUBY
          source "https://rubygems.org"
          gem "bar"
          gemspec
          gem 'bundler', '>= 1.3', group: :development
        RUBY
      end
    end
  end
end
