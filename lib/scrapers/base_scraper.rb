class BaseScraper
  attr_reader :url

  def initialize(url, adapter)
    @url = url
    @adapter = adapter
  end

  private

  attr_reader :adapter

  def page
    @page ||= adapter.get_page(url)
  end
end
