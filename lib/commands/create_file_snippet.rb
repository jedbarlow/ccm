require_relative "../models"
require_relative "command"

module Commands
  class CreateFileSnippet < Command
    CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

    DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))
    CACHE_DIR = File.join(DIR_OF_THIS_FILE, "cache", "snippets")

    attr_accessor :file, :force_full, :quiet

    def initialize(file:, force_full: false, quiet: false)
      @file = file
      @force_full = force_full
      @quiet = quiet
    end

    def call
      snippet_content
    end

    private

    def snippet_content
      content = file_contents(file)

      if force_full || content =~ /.*#{CONTEXT_MARKER}: file\W*$/
        return "```\n#{content}\n```"
      end

      GPT4.new.complete(<<~PROMPT, meta_data_file: file, quiet: quiet)
        Create a snippet version of the following file showing the key content marked by #{CONTEXT_MARKER} (respecting any additional context instructions) surrounded by collapsed code with ellipses and a few key lines to show the basic outline of the file by indentation level. Respond with just the code, no explanations.

        File:
        ```
        #{content}
        ```
      PROMPT
    end

    def file_contents(file)
      IO.read(file)
    end
  end
end
