SearchResultPage = Struct.new(:title, :offer_urls, :url) do
  def self.from_scraper(scraper)
    new(
      scraper.title,
      scraper.offer_urls,
      scraper.url
    ).freeze
  end
end
