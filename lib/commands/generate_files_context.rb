require_relative "command"
require_relative "create_file_snippets"

module Commands
  class GenerateFilesContext < Command
    def initialize(context_types:, task:, context_include: [], quiet: false)
      @context_types = context_types
      @task = task
      @context_include = context_include
      @quiet = quiet
    end

    def call
      snippets = generate_context_snippets
      format_output(snippets)
    end

    private

    def generate_context_snippets
      files = collect_context_files
      CreateFileSnippets.call(files: files, force_full_files: @context_include)
    end

    def collect_context_files
      files = []

      files += ListContextFiles.call if @context_types.include?("m")
      files += AutoSelectContextFiles.call(task: @task, quiet: @quiet) if @context_types.include?("a")
      files += @context_include


      print_no_context_files_warning if files.empty?

      files.sort.uniq
    end

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
