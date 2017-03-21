class SearchResultPageScraper
  attr_reader :url

  def initialize(page, url)
    @page = page
    @url = url
  end

  def title
    page.title.downcase.tr(' ', '_')
  end

  def offer_urls
    page.css('div.om-list-container article a.offer-title__link').map { |row| row['href'] }
  end

  private

  attr_reader :page
end
