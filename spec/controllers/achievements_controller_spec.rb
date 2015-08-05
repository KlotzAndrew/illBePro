require 'rails_helper'

RSpec.describe AchievementsController, :type => :controller do
	describe 'GET #index' do
		# it "responds successfully with an HTTP 200 status code" do
		# 	get :index
		# 	expect(response).to be_success
		# 	expect(response).to have_http_status(200)
		# end

		it "redirects when user not signed-in" do
			get :index
			expect(response).to redirect_to(new_user_session_path)
		end
	end
end