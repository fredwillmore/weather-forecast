require 'rails_helper'
# require 'geocoder'

describe "Home", type: :request do
  describe "GET /index" do
    it "works right" do
      expect do
        get "/"
      end.not_to raise_error
    end
  end

  describe "GET /address_select" do
    let(:result_1) { 
      result = double('Geocoder::Result::Nominatim')
      allow(result).to receive(:display_name).and_return "White House, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20500, United States"
      allow(result).to receive(:coordinates).and_return [38.897699700000004, -77.03655315]
      allow(result).to receive(:postal_code).and_return '20500'
      result
    }
    let(:result_2) { 
      result = double('Geocoder::Result::Nominatim')
      allow(result).to receive(:display_name).and_return "The Oval Office, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20006, United States"
      allow(result).to receive(:coordinates).and_return [38.89737555, -77.0374079114865]
      allow(result).to receive(:postal_code).and_return '20500'
      result
    }

    before do
      allow(Geocoder).to receive(:search).and_return return_value

      post "/address_select", params: { address: ERB::Util.url_encode(address) }
    end

    context "with invalid address" do
      let(:address) { 'Nowhere Land, the Upside Down' }
      let(:return_value) { [] }

      it "works right" do
        expect(response).to be_successful
      end
  
      it 'responds with html' do
        expect(response.content_type).to include("text/html")
      end
    end

    context "with valid address" do
      let(:address) { '1600 Pennsylvania Avenue, washington dc' }
      
      context "when one value is returned" do
        let(:return_value) { [result_1] }

        it 'responds with json' do
          expect(response).to be_successful
          expect(response.content_type).to include("text/html")
          expect(response.body).to include("White House, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20500, United States")
        end
      end
      
      context "when more than one value is returned" do
        let(:return_value) { [result_1, result_2] }

        it 'responds with html' do
          expect(response).to be_successful
          expect(response.content_type).to include("text/html")
          expect(response).to render_template("address_select")
          expect(response.body).to include("The Oval Office, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20006, United States")
          expect(response.body).to include("White House, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20500, United States")
        end
      end
    end
  end

  describe "GET /weather" do
    let(:points) { JSON::parse file_fixture("points.json").read }
    let(:forecast) { JSON::parse file_fixture("forecast.json").read }
    let(:forecast_hourly) { JSON::parse file_fixture("forecast_hourly.json").read }
    let(:points_cached) { nil }
    let(:forecast_cached) { nil }
    let(:forecast_hourly_cached) { nil }

    before do
      allow_any_instance_of(HomeController).to receive(:fetch_resource).with('points').and_return(points)
      allow_any_instance_of(HomeController).to receive(:fetch_resource).with('forecast').and_return(forecast)
      allow_any_instance_of(HomeController).to receive(:fetch_resource).with('forecast_hourly').and_return(forecast_hourly)

      allow(Rails.cache).to receive(:read).with("12345_points").and_return(points_cached)
      allow(Rails.cache).to receive(:read).with("12345_forecast").and_return(forecast_cached)
      allow(Rails.cache).to receive(:read).with("12345_forecast_hourly").and_return(forecast_hourly_cached)

      get "/weather", params: { postal_code: '12345', coordinates: [45.5605,-122.6405] }
    end

    context "when value is from cache" do
      let(:points_cached) { points }
      let(:forecast_cached) { forecast }
      let(:forecast_hourly_cached) { forecast_hourly }

      it 'responds with html' do
        expect(response).to be_successful
        expect(response.content_type).to include("text/html")
        expect(response).to render_template("weather")
        expect(response.body).to include("Monday: A chance of rain showers after 11am. Mostly cloudy, with a high near 57. South southwest wind 5 to 9 mph. Chance of precipitation is 40%.")
        expect(response.body).to include("CONTENT FROM CACHE")
      end
    end

    context "when value is not from cache" do
      it 'responds with html' do
        expect(response).to be_successful
        expect(response.content_type).to include("text/html")
        expect(response).to render_template("weather")
        expect(response.body).to include("Monday: A chance of rain showers after 11am. Mostly cloudy, with a high near 57. South southwest wind 5 to 9 mph. Chance of precipitation is 40%.")
        expect(response.body).not_to include("CONTENT FROM CACHE")
      end
    end
  end
end
