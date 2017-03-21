OfferPage = Struct.new(:address, :mark, :model, :year, :engine, :run, :price_gross, :country, :drive, :gearbox, :url) do
  def self.from_parser(parser)
    new(
      parser.address,
      parser.param('Marka'),
      parser.param('Model'),
      parser.param('Rok produkcji')&.to_i,
      parser.param('Pojemność skokowa', gsub: 'cm3')&.to_i&.round(-2),
      parser.param('Przebieg', gsub: 'km')&.to_i&.round(-2),
      parser.price_gross&.to_i&.round(-2),
      parser.param('Kraj pochodzenia'),
      parser.param('Napęd'),
      parser.param('Skrzynia biegów'),
      parser.url
    ).freeze
  end
end
