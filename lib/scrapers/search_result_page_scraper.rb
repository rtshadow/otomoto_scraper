class SearchResultPageScraper < BaseScraper
  def title
    page.title.downcase.tr(' ', '_')
  end

  def offer_urls
    page.css('div.om-list-container article a.offer-title__link').map { |row| row['href'] }
  end
end
