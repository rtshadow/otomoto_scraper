class Parser
  def initialize(adapter, scraper_class, page_class)
    @adapter = adapter
    @scraper_class = scraper_class
    @page_class = page_class
  end

  def parse(url)
    page_class.from_parser(build_parser(url))
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

  attr_reader :adapter, :scraper_class, :page_class

  def build_parser(url)
    scraper_class.new(html(url), url)
  end

  def html(url)
    adapter.get_page(url)
  end
end
