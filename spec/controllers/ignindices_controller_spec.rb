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

			it "step2 redirect if region nil" do
				session[:setup_progress] = 2
				session[:region_id_temp] = nil
				get :get_setup
				
				expect(session[:setup_progress]).to eq(1)
				expect(response).to redirect_to(setup_path)
			end					

			it "step2 gets 200 with region_id" do
				session[:setup_progress] = 2
				session[:region_id_temp] = 1
				region = FactoryGirl.create(:region)
				
				get :get_setup
				expect(response).to be_success
				expect(response).to have_http_status(200)	
			end

			it "step3 redirect if region nil" do
				session[:setup_progress] = 3
				session[:region_id_temp] = nil
				get :get_setup
				
				expect(session[:setup_progress]).to eq(1)
				expect(response).to redirect_to(setup_path)
			end	

			it "step3 redirect if challenge nil" do
				session[:setup_progress] = 3
				session[:challenge_id] = nil
				get :get_setup
				
				expect(session[:setup_progress]).to eq(1)
				expect(response).to redirect_to(setup_path)
			end	

			it "step3 gets 200 with region_id & challenge_id" do
				session[:setup_progress] = 3
				session[:region_id_temp] = 1
				session[:challenge_id] = 1
				FactoryGirl.create(:staticpage)
				
				get :get_setup
				expect(response).to be_success
				expect(response).to have_http_status(200)	
			end			

			it "step3 grab temp ignindex if !nil?" do
				session[:setup_progress] = 3
				session[:challenge_id] = 1
				session[:region_id_temp] = 1
				session[:summoner_name_ref_temp] = "theoddone"
				FactoryGirl.create(:staticpage)
				ignindex = FactoryGirl.create(:ignindex, :theoddone)
				get :get_setup
				
				expect(session[:ignindex_id]).to eq(ignindex.id)
			end	

			it "step3 uu summoner valid?" do
				session[:setup_progress] = 3
				session[:challenge_id] = 1
				session[:region_id_temp] = 1
				session[:summoner_name_ref_temp] = "theoddone"
				FactoryGirl.create(:staticpage)
				user = subject.current_user
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :validated, :user_id => user.id)
				user.update(ignindex_id: ignindex.id)
				get :get_setup
				
				expect(assigns(:uu_summoner_validated)).to eq(true)
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
		login_user
		
		it 'responds with JSON ignindex id' do
			user = subject.current_user
			ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
			user.update(ignindex_id: ignindex.id)			

			get :show, id: ignindex.id, :format => :json
			body = JSON.parse(response.body)
			
			expect(body["ignindex"]["id"]).to eq(ignindex.id) 
		end	

		it 'responds with JSON ignindex id' do
			user = subject.current_user
			ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
			user.update(ignindex_id: ignindex.id)			

			get :show, id: ignindex.id, :format => :json
			body = JSON.parse(response.body)
			
			expect(body["ignindex"]["id"]).to eq(ignindex.id)
			expect(body["valid"]).to eq(false)
		end	

		it 'responds with valid JSON ignindex id' do
			user = subject.current_user
			ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
			user.update(ignindex_id: ignindex.id)			

			get :show, id: ignindex.id, :format => :json
			body = JSON.parse(response.body)
			
			expect(body["valid"]).to eq(true)
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
			describe 'handles adding postal code' do
				it 'adds in correct session variable' do
					user = subject.current_user
					region = FactoryGirl.create(:region)
					ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				
					post :create, {
						:commit => "Add Postal/Zip Code",
						:ignindex => {
							:postal_code => "m6g" }}
					expect(session[:region_id_temp]).to eq(region.id)
					expect(session[:setup_progress]).to eq(2)
					expect(response).to redirect_to(setup_path)
				end

				it 'does nothing for invalid region' do
					user = subject.current_user
					region = FactoryGirl.create(:region)
					ignindex = FactoryGirl.create(:ignindex, :user_id => user.id)
				
					post :create, {
						:commit => "Add Postal/Zip Code",
						:ignindex => {
							:postal_code => "z1z" }}
					expect(session[:region_id_temp]).to eq(nil)
					expect(session[:setup_progress]).to eq(1)
					expect(response).to redirect_to(setup_path)
				end				
			end

			describe 'handles selecting challange' do
				it 'adds challenge id to session variables' do
					post :create, {
							:commit => "Select",
							:ignindex => {:challenge_id => 1}}
					expect(session[:challenge_id]).to eq(1)
					expect(session[:setup_progress]).to eq(3)
					expect(response).to redirect_to(setup_path)
				end
			end

			describe 'handles adding summoner name' do
				it 'creates a new ignindex for summoner' do
					user = subject.current_user
					session[:challenge_id] = 1
					session[:region_id_temp] = 1

					post :create, {
						:commit => "Add Summoner Name",
						:ignindex => {:summoner_name => "TheOddOne"}}
					expect(Ignindex.all.count).to eq(1)
					expect(user.reload.summoner_id).to eq(Ignindex.last.validation_timer)
					expect(session[:ignindex_id]).to eq(Ignindex.last.id)
				end

				it 'created achievement for new ignindex' do
					user = subject.current_user
					challenge = FactoryGirl.create(:challenge)
					session[:challenge_id] = challenge.id
					session[:region_id_temp] = 1

					post :create, {
						:commit => "Add Summoner Name",
						:ignindex => {:summoner_name => "TheOddOne"}}
					expect(Achievement.all.count).to eq(1)
					expect(Ignindex.last.active_achievement).to eq(Achievement.last.id)
				end

				it 'updates validation trigger if already ignindex' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated)
					session[:challenge_id] = 1
					session[:region_id_temp] = 1

					post :create, {
						:commit => "Add Summoner Name",
						:ignindex => {:summoner_name => "TheOddOne"}}
					expect(user.reload.summoner_id).to eq(Ignindex.last.validation_timer)
					expect(session[:ignindex_id]).to eq(Ignindex.last.id)
				end				
			end
		end
	end

	describe 'POST #update' do
		describe 'user not logged in' do
			it "redirects when user not signed-in" do
				ignindex = FactoryGirl.create(:ignindex, :user_id => 1)

				post :update, id: ignindex.id
				expect(response).to redirect_to(new_user_session_path)
			end
		end
		describe 'user logged in' do
			login_user
			describe 'Add Postal/Zip Code' do
				it 'adds the correct CA postal code' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
					region = FactoryGirl.create(:region, :id => 2)
					user.update(ignindex_id: ignindex.id)	

					post :update, id: ignindex.id, 
							:commit => "Add Postal/Zip Code",
							:ignindex => {
								:postal_code => region.postal_code}
					expect(ignindex.reload.region_id).to eq(region.id)
				end

				it 'does nothing for wrong postal code' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
					region = FactoryGirl.create(:region, :id => 2)
					user.update(ignindex_id: ignindex.id)	

					post :update, id: ignindex.id, 
							:commit => "Add Postal/Zip Code",
							:ignindex => {
								:postal_code => "z1z"}
					expect(ignindex.reload.region_id).to eq(1)
				end

				it 'blocks another users access' do
					ignindex = FactoryGirl.create(:ignindex, :validated)
					region = FactoryGirl.create(:region, :id => 2)

					post :update, id: ignindex.id, 
							:commit => "Add Postal/Zip Code",
							:ignindex => {
								:postal_code => region.postal_code}
					expect(ignindex.reload.region_id).to eq(1)
				end
			end

			describe 'handles generating validation code' do
				it 'syncs user validation timer' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated)
					user.update(ignindex_id: ignindex.id)

					post :update, id: ignindex.id, 
						:commit => "Generate Validation Code"
					expect(user.reload.summoner_id).to eq(ignindex.reload.validation_timer)
				end
			end

			describe 'handles adding summoner name' do
				it 'unbinds current summoner name' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
					user.update(ignindex_id: ignindex.id)

					post :update, id: ignindex.id, 
						:commit => "Change Summoner Name"
					expect(user.reload.ignindex_id).to eq(nil)
					expect(ignindex.reload.user_id).to eq(nil)		
				end

				it 'blocks another users access' do
					user = subject.current_user
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id)
					ignindex2 = FactoryGirl.create(:ignindex, :validated, :user_id => 99)
					user.update(ignindex_id: ignindex.id)

					post :update, id: ignindex2.id, 
						:commit => "Change Summoner Name"
					expect(ignindex2.reload.user_id).not_to eq(nil)			
				end
			end	

			describe 'accepting/upgrading prize' do
				it 'accepts prize' do
					user = subject.current_user
					prize = FactoryGirl.create(:prize, :assignment => 1)
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id, :prize_id => prize.id)
					user.update(ignindex_id: ignindex.id)
					prize.update(ignindex_id: ignindex.id)
					post :update, id: ignindex.id, 
							:commit => "Accept"

					expect(prize.reload.assignment).to eq(2)
					expect(prize.reload.delivered_at).to be_within(10).of(Time.now.to_i)
					expect(ignindex.reload.prize_id).to eq(nil)
				end

				it 'blocks another users access' do
					user = subject.current_user
					prize = FactoryGirl.create(:prize, :assignment => 1)
					ignindex = FactoryGirl.create(:ignindex, :validated, :user_id => user.id, :prize_id => nil)
					ignindex2 = FactoryGirl.create(:ignindex, :validated, :user_id => 99, :prize_id => prize.id)
					user.update(ignindex_id: ignindex.id)
					prize.update(ignindex_id: ignindex2.id)
					post :update, id: ignindex2.id, 
							:commit => "Accept"

					expect(prize.reload.assignment).not_to eq(2)
					expect(prize.reload.delivered_at).not_to be_within(10).of(Time.now.to_i)	
				end
			end			
		end		
	end
end