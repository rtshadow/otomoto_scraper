class OfferPageScraper
  attr_reader :url

  def initialize(page, url)
    @page = page
    @url = url
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
