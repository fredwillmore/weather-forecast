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
      result
    }
    let(:result_2) { 
      result = double('Geocoder::Result::Nominatim')
      allow(result).to receive(:display_name).and_return "The Oval Office, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20006, United States"
      allow(result).to receive(:coordinates).and_return [38.89737555, -77.0374079114865]
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
    before do
      get "/weather", params: { post_code: '12345', coordinates: [45, -122] }
    end

    it 'responds with html' do
      expect(response).to be_successful
      expect(response.content_type).to include("text/html")
      expect(response).to render_template("weather")
      expect(response.body).to include("The Oval Office, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20006, United States")
      expect(response.body).to include("White House, 1600, Pennsylvania Avenue Northwest, Ward 2, Washington, District of Columbia, 20500, United States")
    end
end
end
