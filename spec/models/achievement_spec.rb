require 'rails_helper'

RSpec.describe Achievement, :type => :model do
	describe "model relations" do
		it {should belong_to(:ignindex)}
		it {should belong_to(:challenge)}
		it {should have_many(:statuses)}
		it {should validate_presence_of(:challenge_id)}
	end
end