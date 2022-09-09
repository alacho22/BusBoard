# nethttp.rb
require 'uri'
require 'net/http'
require 'json'

class TfLInterface

  def get_arrivals(stop_id)
    uri = get_arrivals_uri(stop_id)
    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  end

  private

  def get_arrivals_uri(stop_id)
    URI("https://api.tfl.gov.uk/StopPoint/#{stop_id}/Arrivals")
  end
end

class CLI
  def get_stop_id
    puts "Please enter the stop id:"
    gets.chomp
  end

  def print_next_5_arrivals(arrivals)
    arrivals.sort_by! { |arrival| arrival["timeToStation"]}

    next_5_arrivals = arrivals[0, 5]
    next_5_arrivals.each { |arrival| arrival[:minsToStation] = (arrival["timeToStation"] / 60.to_f).ceil}
    formatted_arrivals = next_5_arrivals.map { |arrival| "Line: #{arrival['lineName']}, Destination: #{arrival['destinationName']}, Mins To Arrival: #{arrival[:minsToStation]}"}
    puts formatted_arrivals
  end

end

cli = CLI.new
tfl_interface = TfLInterface.new
stop_id = cli.get_stop_id
arrivals = tfl_interface.get_arrivals(stop_id)
cli.print_next_5_arrivals(arrivals)