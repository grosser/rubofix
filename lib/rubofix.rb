# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class Rubofix
  def initialize(api_key:, model:, context:)
    @api_key = api_key
    @model = model
    @context = context
  end

  def fix!(offense)
    # parse offense
    match = offense.match(/(.+):(\d+):(\d+): /)
    raise "unable to parse offense #{offense}" unless match
    path = match[1]
    line_number = Integer(match[2])
    line, context = lines_from_file(path, line_number)

    # ask openai for a fix
    prompt = <<~PROMPT
      Act as super scared ruby code formatter, that never changes meaning, just formatting.
      This is important production code, nothing except formatting should be changed.

      Fix this rubocop offense: #{offense}
      - Print only the fixed line, NOTHING ELSE
      - Do not change the meaning or intent of the code
      The CONTEXT is as follows:
      #{context.join("\n")}
    PROMPT
    puts "prompt:#{prompt}" if ENV["DEBUG"]
    answer = send_to_openai(prompt)
    puts "answer:\n#{answer}" if ENV["DEBUG"]

    # replace line in file
    answer = answer.strip.sub(/\A```ruby\n(.*)\n```\z/m, "\\1") # it always adds these even when asked to not add
    whitespace = line[/\A\s*/]
    answer = "#{whitespace}#{answer.lstrip}" # it often gets confused and messes up the whitespace
    puts "Fixing #{offense} with:\n#{answer}"
    replace_line_in_file(path, line_number, answer)
  end

  private

  def lines_from_file(file_path, line_number)
    start_line = [line_number - @context, 1].max
    end_line = line_number + @context

    lines = File.read(file_path).split("\n", -1)
    context = lines.each_with_index.map { |l, i| "line #{(i + 1).to_s.rjust(5, " ")}:#{l}" }
    [lines[line_number - 1], context[start_line - 1..end_line - 1]]
  end

  def replace_line_in_file(file_path, line_number, new_line)
    lines = File.read(file_path).split("\n", -1)
    lines[line_number - 1] = new_line
    File.write(file_path, lines.join("\n"))
  end

  def send_to_openai(prompt)
    uri = URI.parse("https://api.openai.com/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{@api_key}"

    request.body = JSON.dump(
      {
        model: @model,
        messages: [{ role: "user", content: prompt }],
        max_tokens: 150
      }
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    raise "Invalid http response #{response.code}:\n#{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)["choices"][0]["message"]["content"]
  end
end
