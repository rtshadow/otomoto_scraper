class OfferPageScraper < BaseScraper
  def address
    page.css('div.seller-box span.seller-box__seller-address__label').text.strip.split("\n").first.strip.squeeze(' ')
  end

  def price_gross
    (gross? ? price : price * 1.23)&.to_i&.round(-2)
  end

  def mark
    param('Marka')
  end

  def model
    param('Model')
  end

  def year
    param('Rok produkcji')&.to_i
  end

  def engine
    param('Pojemność skokowa', gsub: 'cm3')&.to_i&.round(-2)
  end

  def run
    param('Przebieg', gsub: 'km')&.to_i&.round(-2)
  end

  def country
    param('Kraj pochodzenia')
  end

  def drive
    param('Napęd')
  end

  def gearbox
    param('Skrzynia biegów')
  end

  private

  def param(param_name, gsub: '')
    params[param_name]&.gsub(gsub, '')
  end

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
