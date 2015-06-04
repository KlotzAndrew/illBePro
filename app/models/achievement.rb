class Achievement < ActiveRecord::Base
	belongs_to :ignindex
	has_many :statuses
end
