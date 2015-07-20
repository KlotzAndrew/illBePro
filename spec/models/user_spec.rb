require 'rails_helper'

RSpec.describe User, :type => :model do
	describe "model relations" do
		it {should have_one(:ignindex)}
	end
end