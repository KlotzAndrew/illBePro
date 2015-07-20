require 'rails_helper'

RSpec.describe Region, :type => :model do
	describe "model relations" do
		it {should have_many(:prize_regions)}
		it {should have_many(:prizes)}

		it {should have_many(:challenge_regions)}
		it {should have_many(:challenges)}
	end
end