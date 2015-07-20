require 'rails_helper'

RSpec.describe ChallengeRegion, :type => :model do
	describe "model validations" do
		it {should belong_to(:region)}
		it {should belong_to(:challenge)}
	end
end