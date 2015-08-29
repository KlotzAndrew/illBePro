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

end