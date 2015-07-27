require 'rails_helper'



RSpec.describe Status, :type => :model do

  it "has none after one was created in a previous example" do
    expect(Ignindex.count).to eq 0
  end	
  
	describe "model relations" do
		it {should belong_to(:ignindex)}
	end

	describe "model validations" do
		describe "dr_who" do

			it "requires valid summoner name" do
				ignindex = Ignindex.create(
					:summoner_validated => false)
				status = Status.new(
					:ignindex_id => ignindex.id)
				status.valid?

				expect(status.errors).to include(:summoner_required)
			end

			it "requires region_id" do
				ignindex = Ignindex.create(
					:summoner_validated => true,
					:region_id => nil)
				status = Status.create(
					:ignindex_id => ignindex.id)
				status.valid?
			
				expect(status.errors).to include(:region_required)
			end
		end

		describe "one_fox_one_gun" do
			it "allows one running" do
				ignindex = Ignindex.create(
					:summoner_validated => true,
					:region_id => 1)

				status = Status.create(
					:ignindex_id => ignindex.id)
						
				expect(status.reload.id).not_to be_nil
			end

			it "only 1 concurrent" do
				ignindex = Ignindex.create(
					:summoner_validated => true,
					:region_id => 1)
				1.times do |x|
					Status.create(
						:ignindex_id => ignindex.id)
				end

				status1 = Status.create(
					:ignindex_id => ignindex.id)
				status1.valid?

				expect(status1.errors).to include(:you_can)				
			end

			it "throttles at 20/min" do
				20.times do |x|
					ignindex = Ignindex.create(
						:summoner_validated => true,
						:region_id => 1)
					Status.create(
						:ignindex_id => ignindex.id)					
				end
				ignindex = Ignindex.create(
					:summoner_validated => true,
					:region_id => 1)
				status1 = Status.create(
					:ignindex_id => ignindex.id)
				status1.valid?

				expect(status1.errors).to include(:start_queue)							
			end
		end	
	end

	describe "league clockwork method" do

		describe "method components" do
			it "records last time run" do
				static = Staticpage.create
				Status.api_call
				expect(Staticpage.find(1).league_api_ping).to be_within(10).of(Time.now.to_i)
			end

			it "times out after 10 min" do
				Staticpage.create
				ignindex = Ignindex.create(
					:validation_timer => Time.now.to_i - 701)
				Status.api_call

				expect(ignindex.reload.validation_timer).to be_nil
				expect(ignindex.reload.validation_string).to be_nil
			end

			it "updates summoner_id" do
				Staticpage.create
				ignindex = Ignindex.create(
					:validation_timer => Time.now.to_i,
					:summoner_name => "TheOddOne",
					:summoner_name_ref => "theoddone")
				Status.api_call

				expect(ignindex.reload.summoner_id).to eq(60783)
			end

			it "verify mastery" do
				Staticpage.create
				ignindex = Ignindex.create(
					:validation_timer => Time.now.to_i,
					:summoner_name => "TheOddOne",
					:summoner_name_ref => "theoddone",
					:summoner_id => 60783,
					:validation_string => "abc",
					:summoner_validated => false,
					:validation_string => "TIME MAN")
				Status.api_call

				expect(ignindex.reload.summoner_validated).to eq(true)
				expect(ignindex.reload.validation_timer).to be_nil
				expect(ignindex.reload.validation_string).to be_nil
			end

			it "times-out status" do
				Staticpage.create
				ignindex = Ignindex.create(
					:summoner_name => "TheOddOne",
					:summoner_name_ref => "theoddone",
					:summoner_id => 60783,
					:summoner_validated => true,
					:region_id => 1)
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

			it "clockwork win/loss w/ & w/o ach" do
				Staticpage.create
				Champion.create(
					:id => 22,
					:champion => "Ashe")

				#status for win
				ignindex1 = Ignindex.create(
					:summoner_name => "TheOddOne",
					:summoner_name_ref => "theoddone",
					:summoner_id => 60783,
					:summoner_validated => true,
					:region_id => 1)
				status_loss = Status.create(
					:created_at => Time.at(1437883032 - 2143).utc,
					:ignindex_id => ignindex1.id,
					:value => (Time.now.to_i - (1437883032 - 2143 - 100)),
					:kind => 5,
					:summoner_id => ignindex1.summoner_id,
					:summoner_name => ignindex1.summoner_name)

				#status for loss
				ignindex2 = Ignindex.create(
					:summoner_name => "BoxStripe",
					:summoner_name_ref => "boxstripe",
					:summoner_id => 51189734,
					:summoner_validated => true,
					:region_id => 1)
				status_win = Status.create(
					:created_at => Time.at(1437880882 - 1313).utc,
					:ignindex_id => ignindex2.id,
					:value => (Time.now.to_i - (1437880882 - 1313 - 100)),
					:kind => 5,
					:summoner_id => ignindex2.summoner_id,
					:summoner_name => ignindex2.summoner_name)

				#status for win w/ ach
				ignindex3 = Ignindex.create(
					:summoner_name => "Nightblue3",
					:summoner_name_ref => "nightblue3",
					:summoner_id => 25850956,
					:summoner_validated => true,
					:region_id => 1)
				status_win_ach1 = Status.create(
					:created_at => Time.at(1437880882 - 1313).utc,
					:ignindex_id => ignindex3.id,
					:value => (Time.now.to_i - (1437880882 - 1313 - 100)),
					:kind => 5,
					:summoner_id => ignindex3.summoner_id,
					:summoner_name => ignindex3.summoner_name)
				challenge1 = Challenge.create(
					:merchant => "Cora Pizza",
					:available => true,
					:expiery => (Time.now.to_i + 4.weeks.to_i),
					:name => "Cora Pizza Challenge",
					:global => false,
					:global_prizing => false,
					:local_prizing => true,
					:can_spell_name => "CORA",
					:wins_required => 10)
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
				expect(status_loss.reload.win_value).to eq(0)
				expect(status_win.reload.win_value).to eq(2)

				expect(status_win_ach1.reload.win_value).to eq(2)
				expect(achievement1.reload.can_spell_name_open).to eq("COR")
				expect(achievement1.reload.wins_recorded).to eq(1)
			end					
		end


	end


end