class Adapter
  def initialize(host)
    @host = host
  end

  def get_page(url)
    Nokogiri::HTML(open(uri(url)))
  end

  private

  attr_reader :host

  def uri(url)
    URI(url).tap do |uri|
      raise ArgumentError, "#{host} is the only supported site" if uri.host != host
    end
  end
end
