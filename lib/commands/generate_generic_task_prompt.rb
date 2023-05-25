require_relative "command"
require_relative "create_file_snippets"
require_relative "list_context_files"
require_relative "auto_select_context_files"
require_relative "generate_files_context"

module Commands
  class GenerateGenericTaskPrompt < Command
    def initialize(context_types:, task:, quiet: false)
      @context_types = context_types
      @task = task
      @quiet = quiet
    end

    def call
      snippets = GenerateFilesContext.call(context_types: @context_types, task: @task, quiet: @quiet)
      format_output(snippets)
    end

    private

    def format_output(snippets)
      <<~OUTPUT
        Given the following code snippets from a #{ENV["CCM_PROJECT_DESCRIPTION"]}, suggest changes to accomplish the following task in a well structured and high quality manner. Paying attention to the context marked #{CONTEXT_MARKER}. Output only a very brief explanation and the relevant code snippets. Don't output the entire files, just the relevant code snippets.

        Task: #{@task}

        Files:
        #{snippets}
      OUTPUT
    end
  end
end
