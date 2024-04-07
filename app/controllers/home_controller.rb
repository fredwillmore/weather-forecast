class HomeController < ApplicationController
  def index
  end

  # TEMP for getting file fixtures
  def write_fixture(content, file_name)
    return

    file_path = Rails.root.join('spec/fixtures', file_name)
    File.open(file_path, 'w') do |file|
      file.write(content)
    end
  end

  def weather
    if coordinates = params[:coordinates]
      lat = coordinates[0].to_f.round(4)
      lon = coordinates[1].to_f.round(4)
      uri = URI("https://api.weather.gov/points/#{lat},#{lon}")
      
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        weather_report =  JSON::parse(response.body)

        write_fixture(response.body, 'points.json')

        forecast_uri = URI(weather_report['properties']['forecast'])
        forecast_response = Net::HTTP.get_response(forecast_uri)
        if forecast_response.is_a?(Net::HTTPSuccess)
          write_fixture(forecast_response.body, 'forecast.json')
          
          json = forecast_response.body

          forecast = JSON::parse(forecast_response.body)
        else
          error_message = "HTTP request failed with status code #{response.code}"
        end

        forecast_hourly_uri = URI(weather_report['properties']['forecastHourly'])
        forecast_hourly_response = Net::HTTP.get_response(forecast_hourly_uri)
        if forecast_hourly_response.is_a?(Net::HTTPSuccess)
          write_fixture(forecast_hourly_response.body, 'forecast_hourly.json')
          json = forecast_hourly_response.body
          
          forecast_hourly = JSON::parse(forecast_hourly_response.body)
        else
          error_message = "HTTP request failed with status code #{response.code}"
        end
      else
        error_message = "HTTP request failed with status code #{response.code}"
      end
    end

    hours = forecast_hourly['properties']['periods'].slice(0, 24)
    current_temperature = hours.first['temperature']
    low_temperature = hours.map { |period| period['temperature'] }.min
    high_temperature = hours.map { |period| period['temperature'] }.max
    extended_forecast = forecast['properties']['periods'].map do |period|
      { name: period["name"], detailed_forecast: period["detailedForecast"]}
    end
    render :weather, locals: {
      current_temperature: current_temperature,
      low_temperature: low_temperature,
      high_temperature: high_temperature,
      extended_forecast: extended_forecast,
    }
  end
  
  def address_select
    addresses = geocode
    # addresses = []

    render locals: { addresses: addresses }

  rescue StandardError => e
    # Handle exceptions here
    error_message = "An error occurred: #{e.message}"
    # Do something with the error_message

  end

  private

  def geocode
    Geocoder.search(params[:address]).map do |r|
      { display_name: r.display_name, coordinates: r.coordinates, postal_code: r.postal_code }
    end || []

    # render :json => results
  end
end
