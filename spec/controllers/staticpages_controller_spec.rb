require 'rails_helper'

RSpec.describe StaticpagesController, :type => :controller do
	describe 'GET #current_achievement' do
		it "responds successfully with an HTTP 200 status code" do
			get :current_achievement
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end

	describe 'GET #papa_johns' do
		it "responds successfully with an HTTP 200 status code" do
			get :papa_johns
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end

	describe 'GET #about' do
		it "responds successfully with an HTTP 200 status code" do
			get :about
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end

	describe 'GET #contact' do
		it "responds successfully with an HTTP 200 status code" do
			get :contact
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end	

	describe 'GET #faq' do
		it "responds successfully with an HTTP 200 status code" do
			get :faq
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end

	describe 'GET #privacy' do
		it "responds successfully with an HTTP 200 status code" do
			get :privacy
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
	end							
end