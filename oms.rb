require 'rubygems'
require 'nokogiri'
require 'pry'
require 'csv'

require 'open-uri'

class SearchResultPage
  def initialize(page)
    @page = page
  end

  def title
    @title ||= page.title
  end

  def offer_urls
    @offer_urls ||= page.css('div.om-list-container article a.offer-title__link').map { |row| row['href'] }
  end

  private

  attr_reader :page
end

class OfferPage
  def initialize(page)
    @page = page
  end

  def title
    @title ||= page.css('h1.offer-title').text.strip
  end

  def address
    @address ||= page.css('div.seller-box span.seller-box__seller-address__label').text.strip.split("\n").first.strip.squeeze(' ')
  end

  def price
    @price ||= page.css('div.offer-price span.offer-price__number').text.gsub('PLN', '').strip.squeeze(' ').gsub(' ', '').to_i
  end

  def gross?
    page.css('div.offer-price span.offer-price__details').text.downcase.include?('brutto')
  end

  def param(param_name)
    params[param_name]
  end

  private

  attr_reader :page

  def params
    @params ||= page.css('div.offer-params li.offer-params__item').each_with_object({}) do |item, h|
      h[item.css('span.offer-params__label').text.strip] = item.css('div.offer-params__value').text.strip.gsub(' ', '')
    end
  end
end

class Scraper
  def initialize(host)
    @host = host
  end

  def page(url, page_class)
    uri = URI(url)
    raise ArgumentError, "#{host} is the only supported site" if uri.host != host
    yield page_class.new(Nokogiri::HTML(open(uri)))
  end

  private

  attr_reader :host
end


url = ARGV.first
raise ArgumentError, 'No url' if url.nil?

scraper = Scraper.new('www.otomoto.pl')
scraper.page(url, SearchResultPage) do |search_result_page|
  [].tap do |results|
    [].tap do |threads|
      search_result_page.offer_urls.each do |offer_url|
        threads << Thread.new do
          scraper.page(offer_url, OfferPage) do |offer|
            results << [].tap do |column|
              column << offer.address
              column << offer.param('Marka')
              column << offer.param('Model')
              column << offer.param('Rok produkcji')
              column << ((offer.param('Pojemność skokowa')&.gsub('cm3', '')&.to_i&.round(-2)&.to_f || 0) / 1000)
              column << ((offer.param('Przebieg')&.gsub('km', '')&.to_i&.round(-2)&.to_f || 0) / 1000)
              column << (((offer.gross? ? offer.price : (offer.price * 1.23)).to_i.round(-2).to_f || 0) / 1000)
              column << offer.param('Kraj pochodzenia')
              column << offer.param('Napęd')
              column << offer.param('Skrzynia biegów')
              column << offer_url
              print '.'
            end
          end
        end
      end
    end.each(&:join)

    results.sort_by!{ |item| item[6] }

    header = %w(Adres Marka Model Rok Silnik Przebieg Cena Kraj Napęd Skrzynia Url)
    "results/#{search_result_page.title.gsub(' ', '_')}_#{Time.now.to_i}.csv".tap do |path|
      CSV.open(path, 'wb') do |csv|
        csv << header
        results.each do |line|
          csv << line
        end
      end
      puts "\nDone. Results saved to #{path}"
    end

    format = '%-6s %-5s %-6s %-7s %-10s %-10s %-10s %-30s %-35s %-35s'
    print "\n"
    puts format % header[1..10]
    results.each do |line|
      puts format % line[1..10]
    end
  end
end
