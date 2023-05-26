require_relative "../models"
require_relative "command"
require_relative "create_file_snippet"

module Commands
  class CreateFileSnippets < Command
    attr_accessor :files, :force_full_files, :quiet

    def initialize(files:, force_full_files: [], quiet: false)
      @files = files
      @force_full_files = force_full_files
      @quiet = quiet
    end

    def call
      snippets = []
      files.each do |file|
        if File.exists?(file)
          snippet = CreateFileSnippet.call(
            file: file,
            force_full: force_full_files.include?(file),
            quiet: quiet
          )
          snippets << [file, snippet] if snippet
        else
          STDERR.puts "Context file not found: #{file}"
        end
      end

      snippets.map { |(file, snippet)| format_snippet(file, snippet) }.join("\n\n")
    end

    def format_snippet(file_name, snippet)
      "#{file_name}\n#{snippet}\n"
    end
  end
end
