# frozen_string_literal: true
require "bundler/setup"

require "single_cov"
SingleCov.setup :minitest

require "maxitest/global_must"
require "maxitest/autorun"
require "webmock/minitest"
require "mocha/minitest"
require "stringio"

require "rubofix/version"
require "rubofix"

Minitest::Test.class_eval do
  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end

  def with_env(env)
    old = ENV.to_h
    ENV.replace(env.transform_keys(&:to_s))
    yield
  ensure
    ENV.replace(old)
  end
end
