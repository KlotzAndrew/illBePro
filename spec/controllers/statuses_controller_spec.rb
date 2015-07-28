require 'rails_helper'

RSpec.describe StatusesController, :type => :controller do
	describe 'GET #index' do
		it "redirects, route not used" do
			get :index
			expect(response).to redirect_to(root_path)
		end
	end

	describe 'GET #new' do
		it "redirects when user not signed-in" do
			get :new
			expect(response).to redirect_to(new_user_session_path)
		end
	end	
end