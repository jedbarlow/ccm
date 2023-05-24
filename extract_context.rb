require_relative "models"

module ExtractContext
  def self.extract_context(files)
    Runner.run(files)
  end

  class Runner
    def self.run(files)
      snippets = []
      files.each do |file|
        if File.exists?(file)
          snippets << [file, ContextExtractor.snippet_content_for_file(file)]
        else
          STDERR.puts "Context file not found: #{file}"
        end
      end

      snippets.map { |(file, snippet)| SnippetFormatter.format(file, snippet) }.join("\n\n")
    end
  end

  class ContextExtractor
    CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

    DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))
    CACHE_DIR=File.join(DIR_OF_THIS_FILE, "cache", "snippets")

    def self.snippet_content_for_file(file)
      content = file_contents(file)

      if content =~ /.*#{CONTEXT_MARKER}: file\W*$/
        return "```\n#{content}\n```"
      end

      GPT4.new.complete(<<~PROMPT, meta_data_file: file)
      Create a snippet version of the following file showing the key content marked by #{CONTEXT_MARKER} (respecting any additional context instructions) surrounded by collapsed code with ellipses and a few key lines to show the basic outline of the file by indentation level. Respond with just the code, no explanations.

      File:
      ```
      #{content}
      ```
      PROMPT
    end

    def self.file_contents(file)
      IO.read(file)
    end
  end

  class SnippetFormatter
    def self.format(file_name, snippet)
      "#{file_name}\n#{snippet}\n"
    end
  end

  class ColourHelper
    def self.green(text)
      "\e[32m#{text}\e[0m"
    end

    def self.light_green(text)
      "\e[92m#{text}\e[0m"
    end

    def self.red(text)
      "\e[31m#{text}\e[0m"
    end

    def self.light_red(text)
      "\e[91m#{text}\e[0m"
    end
  end
end
