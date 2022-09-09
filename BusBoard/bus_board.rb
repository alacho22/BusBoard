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

tfl_interface = TfLInterface.new

puts tfl_interface.get_arrivals("490008660N")
