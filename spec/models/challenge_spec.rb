require 'rails_helper'

RSpec.describe Challenge, :type => :model do
	describe "model relations" do
		it {should have_many(:achievements)}
		it {should have_many(:challenge_regions)}
		it {should have_many(:regions)}
	end
end