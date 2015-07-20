require 'rails_helper'

RSpec.describe PrizeRegion, :type => :model do
	describe "model validations" do
		it {should belong_to(:region)}
		it {should belong_to(:prize)}
	end
end