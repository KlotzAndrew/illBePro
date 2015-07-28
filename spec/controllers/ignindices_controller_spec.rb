require 'rails_helper'

RSpec.describe IgnindicesController, :type => :controller do
	describe 'GET #landing_page' do
		it "responds successfully with an HTTP 200 status code" do
			get :landing_page
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end
end