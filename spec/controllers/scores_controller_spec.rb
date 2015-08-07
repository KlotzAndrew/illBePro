require 'rails_helper'

RSpec.describe ScoresController, :type => :controller do
	describe 'GET #leaderboard' do
		it "responds successfully with an HTTP 200 status code" do
			get :leaderboard
			expect(response).to be_success
			expect(response).to have_http_status(200)
		end

		it 'renders all active achievements' do
			ignindex = FactoryGirl.create(:ignindex, :theoddone)
			challenge = FactoryGirl.create(:challenge)
			achievement = FactoryGirl.create(:achievement, :ignindex_id => ignindex.id, :challenge_id => challenge.id)
			ignindex.update(active_achievement: achievement.id)

			get :leaderboard
			expect(assigns(:achievements).count).to eq(1) 
		end

		it 'renders progress correctly' do
			ignindex = FactoryGirl.create(:ignindex, :theoddone)
			challenge = FactoryGirl.create(:challenge, :cora_pizza_challenge)
			achievement = FactoryGirl.create(:achievement, :cora_pizza_challenge_part, :ignindex_id => ignindex.id, :challenge_id => challenge.id)
			ignindex.update(active_achievement: achievement.id)

			get :leaderboard
			expect(assigns(:achievements)[0][3]).to eq(14)
		end		
	end

	describe 'GET #index' do
		describe 'user not logged in' do
			it "responds successfully with an HTTP 200 status code" do
				get :index
				expect(response).to be_success
				expect(response).to have_http_status(200)
			end
		end
		describe 'user logged in' do
			login_user
			it 'renders valid ignindex' do
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :validated, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)

				get :index
				expect(assigns(:ignindex)).to eq(ignindex)
			end

			it 'renders valid prize' do
				user = subject.current_user
				prize = FactoryGirl.create(:prize, :cora_pizza)
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :validated, :user_id => user.id, :prize_id => prize.id)
				user.update(ignindex_id: ignindex.id)

				get :index
				expect(assigns(:prize)[:description]).to eq(prize.description)
			end			
		end
	end	
end