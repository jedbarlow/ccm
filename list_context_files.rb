class ListContextFiles
  CONTEXT_MARKER = ENV.fetch("CCM_CONTEXT_MARKER", "IMPORTANT CONTEXT")

  def self.marked_context_files(show_markers = false)
    options = show_markers ? [] : ["-l"]

    ignore_dirs = [".git", "log", "logs", "tmp", "storage", "node_modules", "vendor", ".context"] + ENV.fetch("CCM_IGNORE_DIRS", "").split
    exclude_dirs = ignore_dirs.map { |dir| "--exclude-dir=#{dir}" }

    ignore_files = [".envrc", ".env", "README", "README.md"] + ENV.fetch("CCM_IGNORE_FILES", "").split
    exclude_files = ignore_files.map { |file| "--exclude=\"#{file}\"" }

    grep_command = [
      "grep",
      "\"#{CONTEXT_MARKER}\"",
      *exclude_dirs,
      *exclude_files,
      *options,
      "-r",
      "."
    ].join(" ")

    `#{grep_command} | sort | sed "s/^\\.\\///g"`.lines.map(&:chomp)
  end
end
