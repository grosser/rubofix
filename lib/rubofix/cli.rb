# frozen_string_literal: true

require "shellwords"

class Rubofix
  class CLI
    def run(argv)
      # get config first so we fail fast
      api_key = ENV.fetch("OPENAI_API_KEY")
      model = ENV.fetch("MODEL", "gpt-4o-mini")
      max = Integer(ENV.fetch("MAX", "1"))
      context = Integer(ENV.fetch("CONTEXT", "0"))

      # autocorrect
      puts "Attempting to use builtin autocorrect ..."
      command = "bundle exec rubocop --autocorrect-all #{argv.shelljoin}"
      puts command if ENV["DEBUG"]
      output = `#{command}`
      puts output if ENV["DEBUG"]
      return 0 if $?.success? # nothing to fix

      # get remaining warnings from rubocop
      puts "Getting remaining offenses ..."
      command = "bundle exec rubocop --parallel #{argv.shelljoin}"
      output = remove_shell_colors(`#{command}`)
      return 0 if $?.success? # nothing to fix

      # parse rubocop output
      # output is spam,warnings,spam and we only want warnings
      # warnings format is warning\nline\npointer but we only need the warning
      offenses = output.split("\n\n")[2].split("\n").each_slice(3)
      abort "Unparseable offenses found with command:\n#{command}\n#{output}" if offenses.any? { |w| w.size != 3 }
      offenses = offenses.map(&:first)
      abort "No offenses found\n#{output}" if offenses.empty?

      # fix offenses (in reverse order so line numbers stay correct)
      puts "Fixing MAX=#{max} of #{offenses.size} offenses with MODEL=#{model} ..."
      rubofix = Rubofix.new(api_key: api_key, model: model, context: context)
      offenses.reverse.first(max).each do |warning|
        rubofix.fix! warning
      end

      # don't let users that do not read just assume everything is fine
      if offenses.size > max
        warn "Not all offenses fixed, run again to fix more"
        return 1
      end

      0
    end

    private

    def remove_shell_colors(string)
      string.gsub(/\e\[(\d+)(;\d+)*m/, "")
    end
  end
end
