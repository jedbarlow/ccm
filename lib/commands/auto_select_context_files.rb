require_relative "command"
require_relative "../models"
require_relative "../utils"

module Commands
  class AutoSelectContextFiles < Command
    def initialize(task:, quiet: false)
      @task = task
      @quiet = quiet
    end

    def call
      context_for(@task, quiet: @quiet)
    end

    private

    def context_for(task, quiet: false)
      available_context_files = get_available_context_files

      prompt = <<~PROMPT
        Given the following list of files below from a #{ENV["CCM_PROJECT_DESCRIPTION"]}, select the top 3 to 5 files that would provide relevant context to the task. Respond with just the list of files, no explanation.

        Task: #{task}

        Files:
        #{available_context_files.map { |f| "`#{f}`" }.join("\n")}
      PROMPT

      result = GPT4.new.complete(prompt, quiet: quiet)

      Utils.extract_file_names(result)
    end

    def get_available_context_files
      exclude = %w(.git node_modules log tmp storage spec migrate .context)
      files = Dir.glob(["**/*.rb", "**/*.js", "**/*.erb", "**/*.yml"])
      files.select do |p|
        ps = p.split(File::SEPARATOR);
        exclude.none? { |e| ps.include?(e) }
      end
    end
  end
end
