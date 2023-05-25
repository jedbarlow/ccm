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
