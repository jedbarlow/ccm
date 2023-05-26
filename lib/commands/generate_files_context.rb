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
      generate_context_snippets
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
  end
end
