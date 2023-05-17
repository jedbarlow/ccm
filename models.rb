require "ruby/openai"

class OpenAIModel
  DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))

  API_KEY_ENV_VAR = "CCM_OPENAI_KEY"
  DEFAULT_LOG_FILE = "#{DIR_OF_THIS_FILE}/logs/openai_api.log"

  MAX_RETRIES = 3
  DEFAULT_MODEL="davinci"

  def initialize(model: nil, access_token: nil, log_file: nil)
    access_token ||= ENV[API_KEY_ENV_VAR]
    @client = OpenAI::Client.new(access_token: access_token)
    @model = model || DEFAULT_MODEL
    @log_file = File.open(log_file || DEFAULT_LOG_FILE, "a")
  end

  def complete(prompt)
    MAX_RETRIES.times do
      request_id = SecureRandom.uuid
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @log_file.puts("#{timestamp} #{request_id} Prompt: #{prompt}")

      response = @client.chat(
        parameters: {
          model: @model,
          messages: [
            {
              role: "user",
              content: prompt,
            },
          ],
          user: "dev-tooling-experiments",
        }
      )

      @log_file.puts("#{timestamp} #{request_id} Response: #{response.to_h}")

      result = response.parsed_response["choices"][0]["message"]["content"]

      return result if result.size > 0
    end
  end
end

class GPT4 < OpenAIModel
  def initialize(access_token: nil, log_file: nil)
    super(model: "gpt-4", access_token: access_token, log_file: log_file)
  end
end
