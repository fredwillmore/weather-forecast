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
      from_cache: @from_cache
    }
  rescue StandardError => e
    render :error, locals: { message: e.message }
  end
  
  def address_select
    render locals: { addresses: addresses }
  rescue StandardError => e
    render :error, locals: { message: e.message }
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

  def postal_code
    params[:postal_code]
  end

  def resource_url(name)
    case name
    when "points"
      "https://api.weather.gov/points/#{lat},#{lng}"
    when "forecast"
      points['properties']['forecast']
    when "forecast_hourly"
      points['properties']['forecastHourly']
    end
  end

  def cache_key(name)
    "#{postal_code}_#{name}"
  end

  def fetch_resource(name)
    uri = URI(resource_url(name))
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      set_cached_resource(name, response.body)
      return JSON::parse(response.body)
    else
      raise StandardError.new "HTTP request failed with status code #{response.code}"
    end
  end

  def fetch_cached_resource(name)
    if value = Rails.cache.read(cache_key(name))
      @from_cache = true
      return JSON::parse(value)
    end
    value
  end
  
  def set_cached_resource(name, value)
    Rails.cache.write(cache_key(name), value, expires_in: CACHE_EXPIRE.seconds)
  end

  def points
    @points ||= fetch_cached_resource('points')
    @points ||= fetch_resource('points')
  end
  
  def forecast
    @forecast ||= fetch_cached_resource('forecast')
    @forecast ||= fetch_resource('forecast')
  end
  
  def forecast_hourly
    @forecast_hourly ||= fetch_cached_resource('forecast_hourly')
    @forecast_hourly ||= fetch_resource('forecast_hourly')
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
