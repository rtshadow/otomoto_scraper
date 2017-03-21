require 'rubygems'
require 'nokogiri'
require 'pry'
require 'csv'

require 'open-uri'

class SearchResultPage < Struct.new(:title, :offer_urls, :url)
  def self.from_adapter(adapter, url)
    new(
      adapter.title,
      adapter.offer_urls,
      url
    ).freeze
  end
end

class OfferPage < Struct.new(:address, :mark, :model, :year, :engine, :run, :price_gross, :country, :drive, :gearbox, :url)
  def self.from_adapter(adapter, url)
    new(
      adapter.address,
      adapter.param('Marka'),
      adapter.param('Model'),
      adapter.param('Rok produkcji')&.to_i,
      adapter.param('Pojemność skokowa', gsub: 'cm3')&.to_i&.round(-2),
      adapter.param('Przebieg', gsub: 'km')&.to_i&.round(-2),
      adapter.price_gross&.to_i&.round(-2),
      adapter.param('Kraj pochodzenia'),
      adapter.param('Napęd'),
      adapter.param('Skrzynia biegów'),
      url
    ).freeze
  end
end

class SearchResultPageAdapter
  def initialize(page)
    @page = page
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

class OfferPageAdapter
  def initialize(page)
    @page = page
  end

  def address
    page.css('div.seller-box span.seller-box__seller-address__label').text.strip.split("\n").first.strip.squeeze(' ')
  end

  def price_gross
    gross? ? price : price * 1.23
  end

  def param(param_name, gsub: '')
    params[param_name]&.gsub(gsub, '')
  end

  private

  attr_reader :page

  def price
    @price ||= page.css('div.offer-price span.offer-price__number').text.gsub('PLN', '').strip.squeeze(' ').delete(' ').to_i
  end

  def gross?
    page.css('div.offer-price span.offer-price__details').text.downcase.include?('brutto')
  end

  def params
    @params ||= page.css('div.offer-params li.offer-params__item').each_with_object({}) do |item, h|
      h[item.css('span.offer-params__label').text.strip] = item.css('div.offer-params__value').text.strip.delete(' ')
    end
  end
end

class Scraper
  def initialize(host, adapter_class, page_class)
    @host, @adapter_class, @page_class = host, adapter_class, page_class
  end

  def call(url)
    page_class.from_adapter(adapter_for(url), url)
  end

  private

  attr_reader :host, :adapter_class, :page_class

  def adapter_for(url)
    adapter_class.new(parse_html(url))
  end

  def parse_html(url)
    Nokogiri::HTML(open(uri(url)))
  end

  def uri(url)
    URI(url).tap do |uri|
      raise ArgumentError, "#{host} is the only supported site" if uri.host != host
    end
  end
end

class Presenter
  FORMAT = '%-6s %-5s %-6s %-7s %-10s %-10s %-10s %-30s %-35s %-35s'.freeze

  def initialize(stream, header)
    @stream, @header = stream, header
  end

  def display(results)
    puts_header
    results.each do |result|
      stream.puts FORMAT % result.to_a[1..10]
    end
  end

  private

  attr_reader :stream, :header

  def puts_header
    stream.puts FORMAT % header[1..10]
  end
end

class Repo
  FILE_PATH = 'results/%s_%d.csv'.freeze

  def initialize(header)
    @header = header
  end

  def persist(results, title)
    csv_file(title) do |csv|
      csv << header
      results.each do |result|
        csv << result.to_a
      end
    end
  end

  attr_reader :header

  def csv_file(title)
    (FILE_PATH % [title, Time.now]).tap do |path|
      CSV.open(path, 'wb') do |csv|
        yield csv
      end
      puts "\nResults saved to #{path}"
    end
  end
end

url = ARGV.first
raise ArgumentError, 'No url' if url.nil?
base_url = 'www.otomoto.pl'
offer_scraper = Scraper.new(base_url, OfferPageAdapter, OfferPage)
search_result_scraper = Scraper.new(base_url, SearchResultPageAdapter, SearchResultPage)
header = %w(Adres Marka Model Rok Silnik Przebieg Cena Kraj Napęd Skrzynia Url)
repo = Repo.new(header)
presenter = Presenter.new(STDOUT, header)

search_result_scraper.call(url).tap do |search_result_page|
  [].tap do |results|
    [].tap do |threads|
      search_result_page.offer_urls.each do |offer_url|
        threads << Thread.new do
          results << offer_scraper.call(offer_url)
          print '.'
        end
      end
    end.each(&:join)

    results.sort_by!(&:price_gross)

    repo.persist(results, search_result_page.title)
    presenter.display(results)
  end
end
