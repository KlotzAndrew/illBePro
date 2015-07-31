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

		describe "for logged-in user" do
			login_user
			it "ignindex.new if nil" do
				get :get_setup
				
				expect(assigns(:ignindex)).to be_a_new(Ignindex) 
			end

			it "get existing ignindex if !nil" do
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)
				get :get_setup
				
				expect(assigns(:ignindex)).to eq(user.ignindex) 
			end		

			it "step2 redirect if region nil" do
				session[:setup_progress] = 2
				session[:region_id_temp] = nil
				get :get_setup
				
				expect(session[:setup_progress]).to eq(1)
				expect(response).to redirect_to(setup_path)
			end					

			it "gets 200 with region_id" do
				session[:setup_progress] = 2
				session[:region_id_temp] = 1
				region = FactoryGirl.create(:region)
				
				get :get_setup
				expect(response).to be_success
				expect(response).to have_http_status(200)	
			end		
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

			it 'gets 200 with ignindex' do
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)
				get :zone

				expect(response).to be_success
				expect(response).to have_http_status(200)
			end
		end
	end	

	describe 'GET #index' do
		it 'redirects if user not logged in' do
			get :index
			expect(response).to redirect_to(new_user_session_path) 
		end

		describe "for logged-in user" do
			login_user
			it "redirects without an ignindex" do
				get :index
				expect(response).to redirect_to(setup_path) 
			end			

			it 'gets 200 with ignindex' do
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)
				get :index

				expect(response).to be_success
				expect(response).to have_http_status(200)
			end		
		end
	end	

	describe 'GET #show' do
		it "logs in a user" do
		end		
	end	
end