# nethttp.rb
require 'uri'
require 'net/http'
require 'json'
require 'erb'

class TfLInterface



  def get_all_arrivals(stop_ids)
    all_arrivals = []
    stop_ids.each do |stop_id|
      arrival =  get_arrivals(stop_id)
      all_arrivals += arrival
    end
    all_arrivals
  end

  def get_stop_ids(stop)
    ids = []
    stop["children"].each { |child| ids << child["naptanId"] }
    ids
  end



  def get_nearest_stops(lat, lon)
    uri = get_nearest_stop_uri(lat, lon)
    res = Net::HTTP.get_response(uri)
    json_res = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    stops = json_res["stopPoints"]
    stops.sort_by! { |stop| stop["distance"] }
    stops
  end

  def get_arrivals(stop_id)
    uri = get_arrivals_uri(stop_id)
    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  end

  private

  @@bus_stop_types = ["NaptanBusCoachStation", "NaptanBusWayPoint", "NaptanHailAndRideSection", "NaptanOnstreetBusCoachStopCluster", "NaptanOnstreetBusCoachStopPair", "NaptanPublicBusCoachTram", "TransportInterchange"]

  def get_arrivals_uri(stop_id)
    URI("https://api.tfl.gov.uk/StopPoint/#{stop_id}/Arrivals")
  end

  def get_nearest_stop_uri(lat, lon)
    base_uri = URI("https://api.tfl.gov.uk/StopPoint")
    params = {
      :lat => lat,
      :lon => lon,
      :stopTypes => @@bus_stop_types.join(",")
    }
    base_uri.query = URI.encode_www_form(params)
    base_uri
  end


end

class PostcodeInterface

  def get_postcode_lat_long(postcode)
    uri = get_postcode_lat_long_uri(postcode)
    res = Net::HTTP.get_response(uri)
    json_res = (JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess))["result"]
    {
      :lat => json_res["latitude"],
      :lon => json_res["longitude"]
    }
  end

  private

  def get_postcode_lat_long_uri(postcode)

    URI::HTTP.build(host: "api.postcodes.io", path: "/postcodes/#{ERB::Util::url_encode(postcode)}")
  end

end

class CLI
  def get_stop_id
    puts "Please enter the stop id:"
    gets.chomp
  end

  def get_postcode
    puts "Please enter a postcode:"
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
postcode_interface = PostcodeInterface.new

postcode = cli.get_postcode
postcode_lat_lon = postcode_interface.get_postcode_lat_long(postcode)
postcode_lat = postcode_lat_lon[:lat]
postcode_lon = postcode_lat_lon[:lon]

nearest_stops = tfl_interface.get_nearest_stops(postcode_lat, postcode_lon)

nearest_stop = nearest_stops[0]
nearest_stop_arrivals = tfl_interface.get_all_arrivals(tfl_interface.get_stop_ids(nearest_stop))

puts nearest_stop["commonName"]
cli.print_next_5_arrivals(nearest_stop_arrivals)

second_nearest_stop = nearest_stops[1]
second_nearest_stop_arrivals = tfl_interface.get_all_arrivals(tfl_interface.get_stop_ids(second_nearest_stop))

puts

puts second_nearest_stop["commonName"]
cli.print_next_5_arrivals(second_nearest_stop_arrivals)