require_relative "../models"
require_relative "command"
require_relative "create_file_snippet"

module Commands
  class CreateFileSnippets < Command
    attr_accessor :files

    def initialize(files:)
      @files = files
    end

    def call
      snippets = []
      files.each do |file|
        if File.exists?(file)
          snippets << [file, CreateFileSnippet.call(file: file)]
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
