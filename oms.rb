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

  def brutto?
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

  def page(url)
    uri = URI(url)
    raise ArgumentError, "#{host} is the only supported site" if uri.host != host
    yield Nokogiri::HTML(open(uri))
  end

  private

  attr_reader :host
end


url = ARGV.first
raise ArgumentError, 'No url' if url.nil?

scraper = Scraper.new('www.otomoto.pl')
scraper.page(url) do |page|
  search_result_page = SearchResultPage.new(page)
  path = "results/#{search_result_page.title.gsub(' ', '_')}_#{Time.now.to_i}.csv"
  CSV.open(path, 'wb') do |csv|
    csv << %w(Adres Marka Model Napęd Skrzynia Rocznik Silnik Przebieg Kraj Cena Url)
    [].tap do |threads|
      search_result_page.offer_urls.each do |offer_url|
        threads << Thread.new do
          scraper.page(offer_url) do |offer_page|
            offer = OfferPage.new(offer_page)
            csv << [].tap do |arr|
              arr << offer.address
              arr << offer.param('Marka')
              arr << offer.param('Model')
              arr << offer.param('Napęd')
              arr << offer.param('Skrzynia biegów')
              arr << offer.param('Rok produkcji')
              arr << offer.param('Pojemność skokowa')&.gsub('cm3', '')&.to_i
              arr << offer.param('Przebieg')&.gsub('km', '')&.to_i
              arr << offer.param('Kraj pochodzenia')
              arr << (offer.brutto? ? offer.price : offer.price * 1.23).to_i
              arr << offer_url
              print '.'
            end
          end
        end
      end
    end.each(&:join)
    puts "\nDone. Results saved to #{path}"
  end
end
