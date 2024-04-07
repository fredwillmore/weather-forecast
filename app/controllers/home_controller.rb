class HomeController < ApplicationController
  CACHE_EXPIRE = 1800
  
  def index
  end

  def weather
    render :weather, locals: {
      current_temperature: current_temperature,
      low_temperature: low_temperature,
      high_temperature: high_temperature,
      extended_forecast: extended_forecast,
      from_cache: @from_cache.present?
    }
  rescue StandardError => e
    error_message = "An error occurred: #{e.message}"
  end
  
  def address_select
    render locals: { addresses: addresses }
  rescue StandardError => e
    error_message = "An error occurred: #{e.message}"
  end

  private

  def addresses
    @addresses ||= Geocoder.search(params[:address]).map do |r|
      {
        display_name: r.display_name,
        coordinates: r.coordinates,
        postal_code: r.postal_code
      }
    end
  end

  def lat
    params[:coordinates][0].to_f.round(4)
  end

  def lng
    params[:coordinates][1].to_f.round(4)
  end

  def post_code
    params[:post_code]
  end

  def fetch_resource(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      return JSON::parse(response.body)
    else
      raise StandardError.new "HTTP request failed with status code #{response.code}"
    end
  end

  def fetch_cached_resource(post_code, name)
    key = "#{post_code}_#{name}"

    @from_cache = Rails.cache.read(key)
  end

  def set_cached_resource(post_code, name, value)
    key = "#{post_code}_#{name}"

    Rails.cache.write(key, value, CACHE_EXPIRE)
  end

  def points
    @points ||= fetch_cached_resource(post_code, 'points')
    @points ||= fetch_resource("https://api.weather.gov/points/#{lat},#{lng}")
  end
  
  def forecast
    @forecast ||= fetch_resource(points['properties']['forecast'])
  end
  
  def forecast_hourly
    @forecast_hourly ||= fetch_resource(points['properties']['forecastHourly'])
  end
  
  def hours
    forecast_hourly['properties']['periods'].slice(0, 24)
  end
  
  def current_temperature
    hours.first['temperature']
  end
  
  def low_temperature
    hours.map { |period| period['temperature'] }.min
  end
  
  def high_temperature
    hours.map { |period| period['temperature'] }.max
  end
  
  def extended_forecast
    forecast['properties']['periods'].map do |period|
      { name: period["name"], detailed_forecast: period["detailedForecast"]}
    end
  end
end
