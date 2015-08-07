require 'rails_helper'

RSpec.describe StatusesController, :type => :controller do
	describe 'GET #show' do
		describe 'when not logged-in' do
		end
		login_user

		it 'returns JSON status object'do
			ignindex = FactoryGirl.create(:ignindex, :validated)
			status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)
			get :show, id: status.id, :format => 'json'

			expect(response).to be_success
			expect(response.status).to eq(200)
			expect(response.body).to eq(status.to_json)
		end
	end


	describe 'GET #new' do
		describe 'when not logged-in' do
			it 'redirects to login page' do
				get :new
				expect(response).to redirect_to(new_user_session_path) 
			end
		end	

		describe 'when logged in' do
			login_user
			it 'renders new objects if nil' do
				get :new
				expect(assigns(:status)).to be_a_new(Status)
				expect(assigns(:achievement)).to be_a_new(Achievement)
				expect(assigns(:ignindex)).to be_a_new(Ignindex)
			end

			it 'renders existing object' do
				user = subject.current_user
				achievement = FactoryGirl.create(:achievement)
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id, :active_achievement => achievement.id)
				user.update(ignindex_id: ignindex.id)
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)

				get :new
				expect(assigns(:status)).to eq(status)
				expect(assigns(:achievement)).to eq(achievement)
				expect(assigns(:ignindex)).to eq(ignindex)
			end
		end
	end	

	describe 'POST #create' do
		describe 'when not logged-in' do
			it 'redirects to login page' do
				expect{
				    post :create, status: FactoryGirl.attributes_for(:status)
				  }.to change(Status,:count).by(0)
				expect(response).to redirect_to(new_user_session_path) 
			end
		end	

		describe 'when logged in' do
			login_user
			it 'creates a new status' do
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)

				expect{
				    post :create, status: FactoryGirl.attributes_for(:status)
				  }.to change(Status,:count).by(1)
				expect(response).to redirect_to(root_path) 
			end
		end
	end

	describe 'POST #update' do
		describe 'when not logged-in' do
			it 'redirects to login page' do
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => nil)				
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)

				post :update, id: status.id
				expect(response).to redirect_to(new_user_session_path) 
				expect(status.reload).to eq(status)
			end
		end	

		describe 'when logged-in' do
			login_user
			it 'updates status object' do
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => nil)				
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)

				post :update, id: status.id
				expect(response).to redirect_to(root_path) 
				expect(assigns(:status).trigger_timer).to be_within(10).of(Time.now.to_i)
			end
		end	
	end

	describe 'POST #destroy' do
		describe 'when not logged-in' do
			it 'redirects to login page' do
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => nil)				
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)

				delete :destroy, id: status.id
				expect(response).to redirect_to(new_user_session_path) 
				expect(status.reload).to eq(status)
			end
		end	

		describe 'when logged-in' do
			login_user
			it 'updates status object' do
				ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => nil)				
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)

				delete :destroy, id: status.id
				expect(response).to redirect_to(root_path) 
				expect(assigns(:status).value).to eq(0)
				expect(assigns(:status).win_value).to eq(3)
			end
		end		
	end
end