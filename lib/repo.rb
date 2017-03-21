class Repo
  FILE_PATH = 'results/%s_%d.csv'

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
