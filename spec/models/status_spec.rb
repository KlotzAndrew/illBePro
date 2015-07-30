require 'rails_helper'

RSpec.describe Status, :type => :model do

	it "has a working user factory" do
		FactoryGirl.create(:ignindex)

		expect(Ignindex.count).to eq 1
	end

  it "has none after one was created in a previous example" do
    expect(Ignindex.count).to eq 0
  end	
  
	describe "model relations" do
		it {should belong_to(:ignindex)}
	end

	describe "model validations" do
		describe "dr_who" do

			it "requires valid summoner name" do
				ignindex = FactoryGirl.create(:ignindex)
				status = FactoryGirl.build(:status, :ignindex_id => ignindex.id)
				status.valid?

				expect(status.errors).to include(:summoner_required)
			end

			it "requires region_id" do
				ignindex = FactoryGirl.create(:ignindex, :validated, :region_id => nil)
				status = FactoryGirl.build(:status, :ignindex_id => ignindex.id)
				status.valid?
			
				expect(status.errors).to include(:region_required)
			end
		end

		describe "one_fox_one_gun" do
			it "allows one running" do
				ignindex = FactoryGirl.create(:ignindex, :validated)
				status = FactoryGirl.create(:status, :ignindex_id => ignindex.id)
						
				expect(status.reload.id).not_to be_nil
			end

			it "only 1 status concurrent" do
				ignindex = FactoryGirl.create(:ignindex, :validated)
				1.times do |x|
					FactoryGirl.create(:status, :ignindex_id => ignindex.id)
				end
				status1 = FactoryGirl.build(:status, :ignindex_id => ignindex.id)
				status1.valid?

				expect(status1.errors).to include(:you_can)				
			end

			it "throttles at 20/min" do
				20.times do |x|
					ignindex = FactoryGirl.create(:ignindex, :validated)
					FactoryGirl.create(:status, :ignindex_id => ignindex.id)	
				end
				ignindex = FactoryGirl.create(:ignindex, :validated)
				status1 = FactoryGirl.build(:status, :ignindex_id => ignindex.id)
				status1.valid?

				expect(status1.errors).to include(:start_queue)							
			end
		end	
	end

	describe "league clockwork method" do

		describe "league_summoner_byname" do
			it "records last time run" do
				static = Staticpage.create
				Status.api_call
				expect(Staticpage.find(1).league_api_ping).to be_within(10).of(Time.now.to_i)
			end

			it "times out after 10 min" do
				FactoryGirl.create(:staticpage)
				ignindex = FactoryGirl.create(:ignindex, :timer_off)
				Status.api_call

				expect(ignindex.reload.validation_timer).to be_nil
				expect(ignindex.reload.validation_string).to be_nil
			end

			it "updates summoner_id" do
				Staticpage.create
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :timer_on)
	
				Status.api_call

				expect(ignindex.reload.summoner_id).to eq(60783)
			end
		end

		describe "league_summoner" do
			it "verify mastery" do
				FactoryGirl.create(:staticpage)
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :timer_on, :theoddone_id, :theoddone_page1)

				Status.api_call

				expect(ignindex.reload.summoner_validated).to eq(true)
				expect(ignindex.reload.validation_timer).to be_nil
				expect(ignindex.reload.validation_string).to be_nil
			end
		end

		describe "league_matchhistory" do
			it "times-out status" do
				FactoryGirl.create(:staticpage)
				ignindex = FactoryGirl.create(:ignindex, :theoddone, :theoddone_id, :validated)
				status = Status.create(
					:created_at => Time.at(1437883032 - 2143).utc,
					:ignindex_id => ignindex.id,
					:value => (Time.now.to_i - (1437883032 - 2143 + 1)),
					:kind => 5,
					:summoner_id => ignindex.summoner_id,
					:summoner_name => ignindex.summoner_name)

				Status.api_call
				expect(status.reload.win_value).to eq(1)
			end			

			it "records loss" do
				FactoryGirl.create(:staticpage)
				champ = Champion.create(
					:id => 22,
					:champion => "Ashe")
				ignindex1 = FactoryGirl.create(:ignindex, :theoddone, :theoddone_id, :validated)
				status_loss = Status.create(
					:created_at => Time.at(1437883032 - 2143).utc,
					:ignindex_id => ignindex1.id,
					:value => (Time.now.to_i - (1437883032 - 2143 - 100)), #1st game ago was loss
					:kind => 5,
					:summoner_id => ignindex1.summoner_id,
					:summoner_name => ignindex1.summoner_name)

				Status.api_call
				expect(status_loss.reload.win_value).to eq(0)
				expect(status_loss.reload.game_1[:champion_id]).to eq(champ.champion)
			end

			it "records loss (for long status)" do
				FactoryGirl.create(:staticpage)
				champ = Champion.create(
					:id => 121,
					:champion => "Khazix")
				ignindex1 = FactoryGirl.create(:ignindex, :theoddone, :theoddone_id, :validated)
				status_loss = Status.create(
					:created_at => Time.at(1437878752 - 1337).utc,
					:ignindex_id => ignindex1.id,
					:value => (Time.now.to_i - (1437878752 - 1337 - 100)),
					:kind => 5,
					:summoner_id => ignindex1.summoner_id,
					:summoner_name => ignindex1.summoner_name) #3rd game ago was loss

				Status.api_call
				expect(status_loss.reload.win_value).to eq(0)
				expect(status_loss.reload.game_1[:champion_id]).to eq(champ.champion)
			end			

			it "records win" do
				FactoryGirl.create(:staticpage)
				champ = Champion.create(
					:id => 22,
					:champion => "Ashe")
				ignindex2 = FactoryGirl.create(:ignindex, :boxstripe, :boxstripe_id, :validated)
				status_win = Status.create(
					:created_at => Time.at(1437880882 - 1313).utc,
					:ignindex_id => ignindex2.id,
					:value => (Time.now.to_i - (1437880882 - 1313 - 100)),
					:kind => 5,
					:summoner_id => ignindex2.summoner_id,
					:summoner_name => ignindex2.summoner_name) #2nd game ago was win

				Status.api_call
				expect(status_win.reload.win_value).to eq(2)
				expect(status_win.reload.game_1[:champion_id]).to eq(champ.champion)
			end

			it "win updates ach_wins + ach_letters" do
				FactoryGirl.create(:staticpage)
				champ = Champion.create(
					:id => 22,
					:champion => "Ashe")
				ignindex3 = FactoryGirl.create(:ignindex, :nightblue3, :nightblue3_id, :validated)
				status_win_ach1 = Status.create(
					:created_at => Time.at(1437880882 - 1313).utc,
					:ignindex_id => ignindex3.id,
					:value => (Time.now.to_i - (1437880882 - 1313 - 100)),
					:kind => 5,
					:summoner_id => ignindex3.summoner_id,
					:summoner_name => ignindex3.summoner_name)
				challenge1 = FactoryGirl.create(:challenge, :cora_pizza_challenge)		
				achievement1 = Achievement.create(
					:ignindex_id => ignindex3.id,
			        :region_id => ignindex3.region_id,
			        :challenge_id => challenge1.id,
			        :expire => challenge1.expiery,
			        :name => challenge1.name,
			        :merchant => challenge1.merchant,
			        :has_prizing => challenge1.local_prizing,
			        :can_spell_name => challenge1.can_spell_name,
			        :can_spell_name_open => challenge1.can_spell_name,
			        :wins_required => challenge1.wins_required,
			        :wins_recorded => 0,
			        :con_wins_recorded => 0)
				ignindex3.update(
					:active_achievement => achievement1.id)

				Status.api_call
				expect(status_win_ach1.reload.win_value).to eq(2)
				expect(achievement1.reload.can_spell_name_open).to eq("COR")
				expect(achievement1.reload.wins_recorded).to eq(1)
				expect(status_win_ach1.reload.game_1[:champion_id]).to eq(champ.champion)
			end	

			it "win updates con_wins_recorded" do
				FactoryGirl.create(:staticpage)
				Champion.create(
					:id => 22,
					:champion => "Ashe")
				ignindex3 = FactoryGirl.create(:ignindex, :nightblue3, :nightblue3_id, :validated)
				status_win_ach1 = Status.create(
					:created_at => Time.at(1437880882 - 1313).utc,
					:ignindex_id => ignindex3.id,
					:value => (Time.now.to_i - (1437880882 - 1313 - 100)),
					:kind => 5,
					:summoner_id => ignindex3.summoner_id,
					:summoner_name => ignindex3.summoner_name)
				challenge1 = FactoryGirl.create(:challenge, :hotstreak)
				achievement1 = Achievement.create(
					:ignindex_id => ignindex3.id,
			        :region_id => ignindex3.region_id,
			        :challenge_id => challenge1.id,
			        :expire => challenge1.expiery,
			        :name => challenge1.name,
			        :merchant => challenge1.merchant,
			        :has_prizing => challenge1.local_prizing,
			        :can_spell_name => challenge1.can_spell_name,
			        :can_spell_name_open => challenge1.can_spell_name,
			        :wins_required => challenge1.wins_required,
			        :wins_recorded => 0,
			        :con_wins_recorded => 1)
				ignindex3.update(
					:active_achievement => achievement1.id)

				Status.api_call
				expect(status_win_ach1.reload.win_value).to eq(2)
				expect(achievement1.reload.con_wins_recorded).to eq(2)
			end							
		end


	end


end