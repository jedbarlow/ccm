require "gemini-ai"
require "json"
require "net/http"
require "ruby/openai"
require "uri"

require_relative "colour_helper"
require_relative "snippet_cache"
require_relative "utils"

DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))

class OpenAIModel
  API_KEY_ENV_VAR = "CCM_OPENAI_KEY"
  DEFAULT_LOG_FILE = File.join(DIR_OF_THIS_FILE, "..", "logs", "openai_api.log")

  MAX_RETRIES = 3
  DEFAULT_MODEL="davinci"

  def initialize(model: nil, access_token: nil, log_file: nil)
    access_token ||= ENV[API_KEY_ENV_VAR]
    @client = OpenAI::Client.new(access_token: access_token)
    @model = model || DEFAULT_MODEL
    @log_file = File.open(log_file || DEFAULT_LOG_FILE, "a")
    @cache = SnippetCache.new
  end

  def complete(prompt, meta_data_file: nil, quiet: false)
    cache = @cache.get(cache_key(prompt))

    if cache
      unless quiet
        STDERR.puts "#{ColourHelper.light_green("cache hit")} for #{meta_data_file || Utils.truncate(prompt.lines.first, length: 80)}"
      end
      cache
    else
      unless quiet
        STDERR.puts "#{ColourHelper.light_red("cache miss")} for #{meta_data_file || Utils.truncate(prompt.lines.first, length: 80)}"
      end
      @cache.put(
        original: cache_key(prompt),
        mapped: complete_with_model(prompt)
      )
    end
  end

  private

  def cache_key(prompt)
    @model + prompt
  end

  def complete_with_model(prompt)
    MAX_RETRIES.times do
      request_id = SecureRandom.uuid
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @log_file.puts("#{timestamp} #{request_id} Prompt: #{prompt}")

      begin
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
      rescue => e
        @log_file.puts("#{timestamp} #{request_id} Exception: #{e.message}")
        next
      end

      @log_file.puts("#{timestamp} #{request_id} Response: #{response.to_h}")

      result = response["choices"][0]["message"]["content"]

      return result if result.size > 0
    end
  end
end

class GPT4o < OpenAIModel
  def initialize(access_token: nil, log_file: nil)
    super(model: "gpt-4o", access_token: access_token, log_file: log_file)
  end
end

class GPT4 < OpenAIModel
  def initialize(access_token: nil, log_file: nil)
    super(model: "gpt-4", access_token: access_token, log_file: log_file)
  end
end

class GPT35 < OpenAIModel
  def initialize(access_token: nil, log_file: nil)
    super(model: "gpt-3.5-turbo", access_token: access_token, log_file: log_file)
  end
end

class GeminiModel
  API_KEY_ENV_VAR = "CCM_GEMINI_API_KEY"
  DEFAULT_LOG_FILE = File.join(DIR_OF_THIS_FILE, "..", "logs", "gemini.log")

  MAX_RETRIES = 3
  DEFAULT_MODEL="gemini-2.0-flash"

  def initialize(model: nil, access_token: nil, log_file: nil)
    @client = client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: access_token || ENV[API_KEY_ENV_VAR],
        version: "v1beta",
      },
      options: {model: "gemini-2.0-flash"}
    )
    @model = model || DEFAULT_MODEL
    @log_file = File.open(log_file || DEFAULT_LOG_FILE, "a")
  end

  def complete(prompt, meta_data_file: nil, quiet: false)
    result = @client.generate_content({
      contents: {
        role: "user",
        parts: {text: prompt},
      },
    })
    result.dig("candidates", 0, "content", "parts", 0, "text")
  end
end

class InceptionLabsModel
  API_KEY_ENV_VAR = "CCM_INCEPTION_LABS_API_KEY"
  DEFAULT_LOG_FILE = File.join(DIR_OF_THIS_FILE, "..", "logs", "inceptionlabs.log")

  MAX_RETRIES = 3
  DEFAULT_MODEL="mercury-coder"

  def initialize(model: nil, access_token: nil, log_file: nil)
    @model = model || DEFAULT_MODEL
    @log_file = File.open(log_file || DEFAULT_LOG_FILE, "a")
    @api_key = access_token || ENV[API_KEY_ENV_VAR]
    @api_endpoint = "https://api.inceptionlabs.ai/v1/chat/completions"
  end

  def complete(prompt, meta_data_file: nil, quiet: false)
    payload = {
      "model": @model,
      "messages": [
        { role: "user", content: prompt }
      ],
    }

    # Convert payload to JSON
    json_payload = payload.to_json

    # Create a URI object
    uri = URI(@api_endpoint)

    # Create a new HTTP request
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true  # Enable SSL for secure communication

    # Create a POST request
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}"
    request.body = json_payload

    # Send the request and get the response
    response = http.request(request)

    # Handle the response
    if response.is_a?(Net::HTTPSuccess)
      # Parse the JSON response
      result = JSON.parse(response.body)
      return result["choices"][0]["message"]["content"] if result["choices"] && result["choices"].any?
    else
      puts "Error: #{response.code} - #{response.message}"
      return nil
    end
  end
end
