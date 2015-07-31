require 'rails_helper'

RSpec.describe IgnindicesController, :type => :controller do


	describe 'GET #landing_page' do
		it "responds successfully with an HTTP 200 status code" do
			get :landing_page
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end
		it "assigns new @ignindex" do
			get :landing_page
			expect(assigns(:ignindex)).to be_a_new(Ignindex)
		end
		
	end

	describe 'GET #setup' do
		it 'redirects if user not logged in' do
			get :get_setup
			expect(response).to redirect_to(new_user_session_path) 
		end


	end

	describe 'GET #zone' do
		it 'redirects if user not logged in' do
			get :zone
			expect(response).to redirect_to(new_user_session_path) 
		end

		describe "for logged-in user" do
			login_user
			it "redirects without an ignindex" do
				get :zone
				expect(response).to redirect_to(setup_path) 
			end

			it "has a @zone_pc with @ignindex" do
				get :zone
				expect(subject.current_user.id).to eq(99)
			end			
		end

	end	

	describe 'GET #summoner' do
		it 'redirects if user not logged in' do
			get :index
			expect(response).to redirect_to(new_user_session_path) 
		end
	end		

	describe 'GET #show' do
		it "logs in a user" do
		end		
	end	
end