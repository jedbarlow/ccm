require "optparse"

require_relative "models"
require_relative "auto_context"
require_relative "extract_context"
require_relative "list_context_files"

DIR_OF_SCRIPT = File.dirname(__FILE__)
CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

def generate_context(context_types, task, quiet: false)
  files = []

  if context_types.include?("m")
    files += ListContextFiles.marked_context_files
  end

  if context_types.include?("a")
    files += AutoContext.context_for(task, quiet: quiet)
  end

  if files.empty?
    STDERR.puts "No context files found."
  end

  files = files.sort.uniq

  snippets = ExtractContext.extract_context(files)

  output = <<~OUTPUT
    Given the following code snippets from a #{ENV["CCM_PROJECT_DESCRIPTION"]}, suggest changes to accomplish the following task in a well structured and high quality manner. Paying attention to the context marked #{CONTEXT_MARKER}. Output only a very brief explanation and the relevant code snippets. Don't output the entire files, just the relevant code snippets.

    Task: #{task}

    Files:
    #{snippets}
  OUTPUT

  output
end

def main
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: ccm [options] COMMAND [CONTEXT TASK]"

    opts.on("-q", "--quiet", "Suppress informational and error messages.") do
      options[:quiet] = true
    end
  end.parse!

  command = ARGV[0] || ""
  context_types = (ARGV[1] || "").downcase
  task = (ARGV[2] || "")

  case command
  when "", "l", "list"
    context_markers = ListContextFiles.marked_context_files(show_context: true)

    if context_markers.empty?
      puts "No context files found."
    else
      puts context_markers
    end
  when "c", "clear"
    `sed -i "" "/^.*#{CONTEXT_MARKER}.*$/d" #{ListContextFiles.marked_context_files.map {|f| "\"#{f}\""}.join(" ")}`
  when "g", "gc", "generate", "generate-copy"
    output = generate_context(context_types, task, quiet: options[:quiet])

    if command == "gc" || command == "generate-copy"
      # replace pbcopy with equivalent Ruby clipboard functionality
    else
      puts output
    end
  else
    puts "Unknown command: #{command}"
  end
end

main
