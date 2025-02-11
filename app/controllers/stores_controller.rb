class StoresController < ApplicationController
require 'net/http'
require 'json'

class StoresController < ApplicationController
  def find_stores
    lat = params[:lat]
    lng = params[:lng]
    radius = params[:radius] || 5000 # Default: 5km

    if lat.blank? || lng.blank?
      return render json: { error: "Latitude and Longitude are required" }, status: :bad_request
    end

    # Overpass API query for Daily Yamazaki stores
    query = <<~QUERY
      [out:json];
      node[shop=convenience][name~"Daily Yamazaki"](around:#{radius},#{lat},#{lng});
      out;
    QUERY

    url = URI("https://overpass-api.de/api/interpreter?data=#{URI.encode_www_form_component(query)}")

    begin
      response = Net::HTTP.get(url)
      stores = JSON.parse(response)["elements"]

      formatted_stores = stores.map do |store|
        {
          name: store.dig("tags", "name") || "Unknown Name",
          latitude: store["lat"],
          longitude: store["lon"], # ✅ Fix: Ensure correct key is used
          address: store.dig("tags", "addr:full") || "Unknown Address"
        }
      end

      render json: formatted_stores
    rescue StandardError => e
      render json: { error: "Failed to retrieve store locations: #{e.message}" }, status: :internal_server_error
    end
  end
end
end
