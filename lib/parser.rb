class Parser
  def initialize(adapter, scraper_class, entity_class)
    @adapter = adapter
    @scraper_class = scraper_class
    @entity_class = entity_class
  end

  def parse(url)
    entity_class.from_scraper(build_scraper(url))
  end

  def concurrently_parse(urls)
    results = []
    threads = []

    urls.each do |url|
      threads << Thread.new do
        results << parse(url)
        print '.'
      end
    end

    threads.each(&:join)
    results
  end

  private

  attr_reader :adapter, :scraper_class, :entity_class

  def build_scraper(url)
    scraper_class.new(url, adapter)
  end
end
