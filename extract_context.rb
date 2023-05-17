require_relative "models"

class Runner
  def self.run(files)
    snippets = []
    files.each do |file|
      snippets << [file, ContextExtractor.snippet_content_for_file(file)]
    end

    output = snippets.map { |(file, snippet)| SnippetFormatter.format(file, snippet) }.join("\n\n")
    puts output
  end
end

class ContextExtractor
  DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))
  CACHE_DIR=File.join(DIR_OF_THIS_FILE, "cache", "snippets")

  def self.cache_file_for_hash(hash)
    File.join(CACHE_DIR, hash)
  end

  def self.hash(content)
    Digest::SHA256.hexdigest(content)
  end

  def self.file_contents(file)
    IO.read(file)
  end

  def self.cached_snippet(hash)
    cache_file = cache_file_for_hash(hash)
    File.exists?(cache_file) ? file_contents(cache_file) : nil
  end

  def self.populate_cache(content)
    hash = self.hash(content)
    cache_file = cache_file_for_hash(hash)
    snippet = self.generate_snippet(content)

    IO.write(cache_file, snippet)

    snippet
  end

  def self.generate_snippet(content)
    GPT4.new.complete(<<~PROMPT)
    Create a very concise snippet version of the following file showing only the key content marked by IMPORTANT CONTEXT surrounded by collapsed code with ellipses and a few key lines to show the basic outline of the file by indentation level. Output just the code, no explanations.

    File:
    ```
    #{content}
    ```
    PROMPT
  end

  def self.snippet_content_for_file(file)
    content = file_contents(file)
    hash = hash(content)

    cache = cached_snippet(hash)

    if cache
      STDERR.puts "#{ColourHelper.light_green("cache hit")} for #{file}"
      cache
    else
      STDERR.puts "#{ColourHelper.light_red("cache miss")} for #{file}"
      populate_cache(content)
    end
  end
end

class SnippetFormatter
  def self.format(file_name, snippet)
    "#{file_name}\n" + "#{snippet}\n"
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

Runner.run(ARGV)

#
# An earlier experiment with more manual context identifiers, not using LLMs for snippet formation.
#
# class MarkedContextExtractor
#   def self.extract(filename)
#     lines = File.readlines(filename)
#
#     start_index = lines.index { |line| line =~ /CONTEXT START/ }
#     end_index = lines.index { |line| line.strip =~ /CONTEXT END/ }
#
#     if start_index.nil? || end_index.nil?
#       puts "The context markers were not found in the file."
#       return
#     end
#
#     context_indentation = self.indentation(lines[start_index])
#
#     upper_context = self.scan_indentation_drops(
#       lines: lines,
#       start_index: start_index - 1,
#       indentation: context_indentation,
#       direction: :up,
#     )
#
#     lower_context = self.scan_indentation_drops(
#       lines: lines,
#       start_index: end_index + 1,
#       indentation: context_indentation,
#       direction: :down,
#     )
#
#     (
#       [
#         "#{filename}",
#         "```",
#       ] +
#       upper_context +
#       lines[(start_index+1)...end_index] +
#       lower_context +
#       [
#         "```",
#       ]
#     )
#   end
#
#   def self.indentation(line)
#     line.match(/^(\s*)/)[0] || ""
#   end
#
#   def self.blank?(line)
#     stripped = line.strip
#     stripped.empty? || stripped.start_with?("#") || stripped.start_with?("/") || stripped.start_with?("<%#")
#   end
#
#   def self.scan_indentation_drops(lines:, start_index:, indentation:, direction:)
#     result_lines = []
#     i = start_index
#     current_indentation = indentation
#
#     while i >= 0 && i < lines.size
#       unless blank?(lines[i])
#         line_identation = self.indentation(lines[i])
#
#         if line_identation.size == current_indentation.size && result_lines.last != "#{current_indentation}..."
#           result_lines << "#{current_indentation}..."
#         end
#
#         if line_identation.size < current_indentation.size
#           result_lines << lines[i]
#           current_indentation = line_identation
#         end
#       end
#
#       if direction == :up
#         i -= 1
#       else
#         i += 1
#       end
#     end
#
#     if direction == :up
#       result_lines.reverse
#     else
#       result_lines
#     end
#   end
# end
