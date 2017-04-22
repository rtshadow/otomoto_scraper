class Presenter
  FORMAT = '%-6s %-5s %-6s %-7s %-10s %-10s %-10s %-30s %-35s %-40s %-45s'

  def initialize(stream, header)
    @stream = stream
    @header = header
  end

  def display(results)
    puts_header
    results.each do |result|
      stream.puts FORMAT % result.to_a[1..12]
    end
  end

  private

  attr_reader :stream, :header

  def puts_header
    stream.puts FORMAT % header[1..12]
  end
end
