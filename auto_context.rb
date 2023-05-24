require_relative "models"
require_relative "utils"

def main
  task = ARGV[0]

  available_context_files = get_available_context_files

  prompt = <<~PROMPT
    Given the following list of files below from a #{ENV["CCM_PROJECT_DESCRIPTION"]}, select the top 3 to 5 files that would provide relevant context to the task. Respond with just the list of files, no explanation.

    Task: #{task}

    Files:
    #{available_context_files.map { |f| "`#{f}`" }.join("\n")}
  PROMPT

  STDERR.puts prompt

  result = GPT4.new.complete(prompt)

  context_files = Utils.extract_file_names(result)

  puts context_files
end

def get_available_context_files
  # list all files, excluding directories: spec node_modules .git log tmp storage .context 
  exclude = %w(.git node_modules log tmp storage spec migrate .context)
  files = Dir.glob(["**/*.rb", "**/*.js", "**/*.erb", "**/*.yml"])
  files.select do |p|
    ps = p.split(File::SEPARATOR);
    exclude.none? { |e| ps.include?(e) }
  end
end

main
