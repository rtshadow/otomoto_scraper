OfferPage = Struct.new(:address, :mark, :model, :year, :engine, :run, :price_gross, :country, :drive, :gearbox, :url) do
  def self.from_scraper(scraper)
    new(
      scraper.address,
      scraper.mark,
      scraper.model,
      scraper.year,
      scraper.engine,
      scraper.run,
      scraper.price_gross,
      scraper.country,
      scraper.drive,
      scraper.gearbox,
      scraper.url
    ).freeze
  end
end
