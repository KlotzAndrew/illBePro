require 'rails_helper'

RSpec.describe Status, :type => :model do

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

		describe "stubbing resources" do
			it 'stubbing summoner_id' do
				uri = URI('https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/hideonbush?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72')
				response = Net::HTTP.get(uri)
				expect(response).to be_an_instance_of(String)
			end

			it 'stubbing mastery_page' do
				uri = URI("https://na.api.pvp.net/api/lol/na/v1.4/summoner/64807930/masteries?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72")
				response = Net::HTTP.get(uri)
				expect(response).to be_an_instance_of(String)
			end

			it 'stubbing matchistory' do
				uri = URI("https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/64807930?api_key=cfbf266e-d1db-4aff-9fc2-833faa722e72")
				response = Net::HTTP.get(uri)
				expect(response).to be_an_instance_of(String)				
			end
		end

		static = Staticpage.create

		it "records last time run" do
			Status.api_call
			expect(Staticpage.find(1).league_api_ping).to be_within(10).of(Time.now.to_i)
		end

		describe "section summoner_id" do
			describe "times out after 10 min" do
				ignindex = Ignindex.create(
					:validation_timer => Time.now.to_i - 601)

				Status.api_call
				it "sets timer to nil" do
					expect(ignindex.reload.validation_timer).to be_nil
				end

				it "sets string to nil" do
					expect(ignindex.reload.validation_string).to be_nil
				end
			end

			describe "updates summoner_id" do
				# ignindex = Ignindex.create(
				# 	:validation_timer => Time.now.to_i,
				# 	:summoner_name => "Hide on Bush")

				# Status.api_call
				# it "updates summoner_name_ref" do
				# 	expect(ignindex.reload.summoner_name_ref).to eq(ignindex.summoner_name.mb_chars.downcase.gsub(' ', '').to_s)
				# end
			end
		end

		describe "section verify mastery" do
		end

		describe "section handle statuses" do
		end			
	end
end