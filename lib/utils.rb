require "tiktoken_ruby"

module Utils
  # Given a string like the following,
  # "`app/controllers/api/quizzes_controller.rb`
  #  `app/controllers/api/tracks_controller.rb`
  #  `app/controllers/graphql_controller.rb`
  #  `app/graphql/mutations/base_mutation.rb`
  #  `app/graphql/mutations/create_quiz.rb`
  # "
  #
  # Return an array of strings like the following:
  # [
  #  "app/controllers/api/quizzes_controller.rb",
  #  "app/controllers/api/tracks_controller.rb",
  #  "app/controllers/graphql_controller.rb",
  #  "app/graphql/mutations/base_mutation.rb",
  #  "app/graphql/mutations/create_quiz.rb"
  # ]
  def self.extract_file_names(str)
    back_tick_extractor = /`([^`]+)`/m
    str.scan(back_tick_extractor).flatten
  end

  def self.extract_first_code_snippet(str)
    match = str.match(/^```\w*\n(.*)\n```/m)
    if match
      match[1]
    else
      str
    end
  end

  def self.truncate(str, length: 80)
    str.length > length ? "#{str[0...(length-3)]}..." : str
  end

  def self.token_count(str)
    enc = Tiktoken.encoding_for_model("gpt-3.5-turbo")
    str.length
    enc.encode(str).length
  end

  def self.smart_extract_code(str)
    # If there are multiple code blocks, however, return the entire string.
    # Extracts the first code block from a string, handling both fenced blocks.

    fenced_code_blocks = str.scan(/```(?:\w*)\n(.*?)\n```/m)
    if fenced_code_block.length == 1
      fenced_code_block[0][0]
    else
      str
    end
  end
end
