require 'rails_helper'

RSpec.describe Ignindex, :type => :model do
	describe "model relations" do
		it {should have_many(:statuses)}
		it {should belong_to(:region)}
		it {should have_many(:achievements)}
		it {should have_many(:prizes)}
	end

	describe "methods ignindex refreshers" do
		it "refreshes validation summoner" do
			ignindex = Ignindex.new(
				:validation_timer => Time.now.to_i,
				:validation_string => "pizza-wins")
			
			ignindex.refresh_summoner
			expect(ignindex.validation_timer).to eq(nil)
			expect(ignindex.validation_string).to eq(nil)
		end

		it "refreshes validation timer" do
			ignindex = Ignindex.new(
				:validation_timer => 1,
				:validation_string => "a")

			ignindex.refresh_validation
			expect(ignindex.validation_timer).to be_within(10).of(Time.now.to_i)
			expect(ignindex.validation_string).to match /[a-z]{5}.[a-z]{4}/
		end
	end

	describe "method assign prize" do


		describe "valid prize" do

			describe "prize not attached to ignindex" do
				prize = Prize.create(
					:assignment => 1)
				ignindex = Ignindex.create(
					:prize_id => prize.id)

				ignindex.assign_prize("Accept")
				it "does not assign prize" do
					expect(prize.reload.assignment).not_to eq(2)
				end
			end

			describe "assigns prize for 'accept'" do
				prize = Prize.create(
					:assignment => 1)
				ignindex = Ignindex.create(
					:prize_id => prize.id)
				prize.update(
					:ignindex_id => ignindex.id)				
				ignindex.assign_prize("Accept")

				it "prize marked as accepted" do
					expect(prize.reload.assignment).to eq(2)
				end

				it "prize marked as delivered" do
					expect(prize.reload.delivered_at).to be_within(10).of(Time.now.to_i)
				end

				it "marks ignindex prize_id open" do
					expect(ignindex.reload.reload.prize_id).to eq(nil)
				end

				it "marks last prize for ignindex" do
					expect(ignindex.reload.last_prize_time).to be_within(10).of(Time.now.to_i)
				end
			end
		end
	end
end