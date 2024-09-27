# frozen_string_literal: true
name = "rubofix"
$LOAD_PATH << File.expand_path("lib", __dir__)
require "#{name.tr("-", "/")}/version"

Gem::Specification.new name, Rubofix::VERSION do |s|
  s.summary = "Auto fix all rubocop warnings with chatgpt / openai / local llm"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = ">= 3.1.0"
end
