SearchResultPage = Struct.new(:title, :offer_urls, :url) do
  def self.from_parser(parser)
    new(
      parser.title,
      parser.offer_urls,
      parser.url
    ).freeze
  end
end
