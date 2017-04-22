#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'pry'
require 'csv'

require 'open-uri'

require_relative 'lib/entities/offer_page'
require_relative 'lib/entities/search_result_page'
require_relative 'lib/scrapers/base_scraper'
require_relative 'lib/scrapers/offer_page_scraper'
require_relative 'lib/scrapers/search_result_page_scraper'
require_relative 'lib/parser'
require_relative 'lib/repo'
require_relative 'lib/presenter'
require_relative 'lib/adapter'

url = ARGV.first
raise ArgumentError, 'No url' if url.nil?
adapter = Adapter.new('www.otomoto.pl')
offer_parser = Parser.new(adapter, OfferPageScraper, OfferPage)
search_result_parser = Parser.new(adapter, SearchResultPageScraper, SearchResultPage)
header = %w(Adres Marka Model Rok Silnik Przebieg Cena Kraj Napęd Skrzynia Wyposazenie Url)
repo = Repo.new(header)
presenter = Presenter.new(STDOUT, header)

search_result_page = search_result_parser.parse(url)
results = offer_parser.concurrently_parse(search_result_page.offer_urls)

results.sort_by!(&:price_gross)

repo.persist(results, search_result_page.title)
presenter.display(results)
