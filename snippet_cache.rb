class SnippetCache
  DIR_OF_THIS_FILE = File.dirname(File.expand_path(__FILE__))
  DEFAULT_CACHE_DIR = File.join(DIR_OF_THIS_FILE, "cache", "snippets")

  def initialize(cache_dir: DEFAULT_CACHE_DIR)
    @cache_dir = cache_dir
  end

  def get(content)
    get_by_hash(hash(content))
  end

  def put(original:, mapped:)
    hash = hash(original)
    cache_file = cache_file_for_hash(hash)
    IO.write(cache_file, mapped)
    mapped
  end

  private

  def get_by_hash(hash)
    cache_file = cache_file_for_hash(hash)
    File.exists?(cache_file) ? file_contents(cache_file) : nil
  end

  def cache_file_for_hash(hash)
    File.join(@cache_dir, hash)
  end

  def hash(content)
    Digest::SHA256.hexdigest(content)
  end

  def file_contents(file)
    IO.read(file)
  end
end

