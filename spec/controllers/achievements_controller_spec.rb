require 'rails_helper'

RSpec.describe AchievementsController, :type => :controller do
	describe 'GET #index' do
		describe 'user not logged in' do
			it "redirects when user not signed-in" do
				get :index
				expect(response).to redirect_to(new_user_session_path)
			end
		end

		describe 'user logged in' do
			login_user
			it 'renders active challenge' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id, :region_id => region.id)
				achievement = FactoryGirl.create(:achievement, :ignindex_id => ignindex.id)
				ignindex.update(active_achievement: achievement.id)

				get :index
				expect(assigns[:all_challenges][:active].first).to eq(achievement)
			end

			it 'rendered saved challenge options' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id, :region_id => region.id)
				achievement = FactoryGirl.create(:achievement, :ignindex_id => ignindex.id)

				get :index
				expect(assigns[:all_challenges][:saved].first).to eq(achievement)
			end

			it 'renders local challenge options' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge, :local)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id, :region_id => region.id)
				region.challenges << challenge

				get :index
				expect(assigns[:all_challenges][:local].first).to eq(challenge)
			end

			it 'renders country challenge options' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge, :country)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id, :region_id => region.id)

				get :index
				expect(assigns[:all_challenges][:country].first).to eq(challenge)				
			end

			it 'renders global challenge options' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge, :global)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id, :region_id => region.id)

				get :index
				expect(assigns[:all_challenges][:global].first).to eq(challenge)								
			end
		end
	end

	describe 'POST #create' do
		describe 'user not logged in' do
			it "redirects when user not signed-in" do
				post :create
				expect(response).to redirect_to(new_user_session_path)
			end
		end

		describe 'user logged in' do
			login_user
			it 'activates correct achievement' do
				user = subject.current_user
				challenge = FactoryGirl.create(:challenge, :global)
				ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				achievement = FactoryGirl.create(:achievement, :ignindex_id => ignindex.id)
				user.update(ignindex_id: ignindex.id)

				post :create, {
					:commit => "Activate",
					:achievement => {
						:achievement_id => achievement.id
						}}
				expect(ignindex.reload.active_achievement).to eq(achievement.id)
				expect(response).to redirect_to(root_path) 
			end

			it 'selects correct challenge' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge, :global)
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)

				post :create, {
					:commit => "Select",
					:achievement => {
						:challenge_id => challenge.id
						}}
				expect(ignindex.reload.active_achievement).to eq(1)
				expect(Achievement.all.count).to eq(1)
				expect(response).to redirect_to(root_path) 
			end

			it 'does nothing for wrong challenge' do
				user = subject.current_user
				region = FactoryGirl.create(:region)
				challenge = FactoryGirl.create(:challenge, :global)
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)

				post :create, {
					:commit => "Select",
					:achievement => {
						:challenge_id => 999
						}}
				expect(ignindex.reload.active_achievement).to eq(nil)
				expect(Achievement.all.count).to eq(0)
			end			
		end
	end
end