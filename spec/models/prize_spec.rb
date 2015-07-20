require 'rails_helper'

RSpec.describe Prize, :type => :model do
	describe "model validations" do
		it {should have_many(:prize_regions)}
		it {should have_many(:regions)}
		it {should have_one(:ignindex)}
	end
end