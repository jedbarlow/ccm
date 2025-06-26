require "optparse"

require_relative "commands"
require_relative "models"
require_relative "utils"

CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

def generate_context(context_types, task, context_include: [], quiet: false)
  Commands::GenerateGenericTaskPrompt.call(context_types: context_types, task: task, context_include: context_include, quiet: quiet)
end

def select_model(model_name)
  case model_name
  when "gpt4o"
    GPT4o.new
  when "gpt4"
    GPT4.new
  when "gpt3"
    GPT35.new
  when "gemini-2.5-flash"
    GeminiModel.new(model: "gemini-2.5-flash")
  when "mercury-coder"
    InceptionLabsModel.new
  else
    raise "Unknown model: #{model_name}"
  end
end

def main
  options = {
    context_include: []
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: ccm [options] [COMMAND [CONTEXT TASK [CODE]]]"

    opts.on("-q", "--quiet", "Suppress informational and error messages.") do
      options[:quiet] = true
    end

    opts.on("-i", "--stdin", "accept code via stdin instead of as an CLI parameter.") do
      options[:code_stdin] = true
    end

    opts.on("-mMODEL", "--model=MODEL", "Model preference (3 or 4, 4o for GPT3.5 and GPT4 and GPT4o); not all commands support.") do |model|
      options[:model] = model
    end

    opts.on("-c", "--context-include FILE", "Include file as context (full file)") do |file|
      options[:context_include] << file
    end
  end.parse!

  options[:model] ||= "gpt4o"

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
    context_types = "m" if context_types.strip.empty?
    output = generate_context(context_types, task, context_include: options[:context_include], quiet: options[:quiet])

    if command == "gc" || command == "generate-copy"
      IO.popen("pbcopy", "w") { |f| f << output }
      puts "Output copied to clipboard."
    else
      puts output
    end
  when "m", "modify"
    context = if context_types == "n"
      ""
    else
      snippets = Commands::GenerateFilesContext.call(context_types: context_types, task: task, quiet: options[:quiet])
      "# Context files:\n#{snippets}\n"
    end

    result = select_model(options[:model]).complete(<<~PROMPT, quiet: options[:quiet])
      #{context}
      Given the context files and code, make the specified changes to the following code snippet. Respond with just the code, no explanations or other text. In the case of outputing multiple files, output each file as a backtick block.

      # Code
      ```
      #{code}
      ```

      # Task
      Change: #{task}
    PROMPT

    puts Utils.extract_first_code_snippet(result)
  else
    puts "Unknown command: #{command}"
  end
end

main
