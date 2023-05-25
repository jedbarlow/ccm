require "optparse"

require_relative "commands"
require_relative "models"
require_relative "utils"

CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

def generate_context(context_types, task, quiet: false)
  Commands::GenerateGenericTaskPrompt.call(context_types: context_types, task: task, quiet: quiet)
end

def select_model(model_name)
  case model_name
  when "gpt4"
    GPT4.new
  when "gpt3"
    GPT35.new
  else
    raise "Unknown model: #{model_name}"
  end
end

def main
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: ccm [options] COMMAND [CONTEXT TASK [CODE]]"

    opts.on("-q", "--quiet", "Suppress informational and error messages.") do
      options[:quiet] = true
    end

    opts.on("-i", "--stdin", "accept code via stdin instead of as an CLI parameter.") do
      options[:code_stdin] = true
    end

    opts.on("-mMODEL", "--model=MODEL", "Model preference (3 or 4, for GPT3.5 and GPT4); not all commands support.") do |model|
      options[:model] = model
    end
  end.parse!

  options[:model] ||= "gpt4"

  command = ARGV[0] || ""
  context_types = (ARGV[1] || "").downcase
  task = (ARGV[2] || "")
  code = options[:code_stdin] ? STDIN.read : (ARGV[3] || "")

  case command
  when "", "l", "list"
    context_markers = Commands::ListContextFiles.call(show_markers: true)

    if context_markers.empty?
      puts "No context files found."
    else
      puts context_markers
    end
  when "c", "clear"
    `sed -i "" "/^.*#{CONTEXT_MARKER}.*$/d" #{Commands::ListContextFiles.call.map {|f| "\"#{f}\""}.join(" ")}`
  when "g", "gc", "generate", "generate-copy"
    output = generate_context(context_types, task, quiet: options[:quiet])

    if command == "gc" || command == "generate-copy"
      # replace pbcopy with equivalent Ruby clipboard functionality
    else
      puts output
    end
  when "m", "modify"
    context = if context_types == "n"
      ""
    else
      snippets = Commands::GenerateFilesContext.call(context_types: context_types, task: task, quiet: options[:quiet])
      "\nContext files:\n#{snippets}"
    end

    result = select_model(options[:model]).complete(<<~PROMPT, quiet: options[:quiet])
      Given the following context files, code, and code change task, make the specified code changes to the following code snippet. Respond with just the code, no explanations.

      Change: #{task}

      Code:
      ```
      #{code}
      ```
      #{context}
    PROMPT

    puts Utils.extract_first_code_snippet(result)
  else
    puts "Unknown command: #{command}"
  end
end

main
