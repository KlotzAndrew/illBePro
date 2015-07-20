class Prize < ActiveRecord::Base

has_many :prize_regions
has_many :regions, through: :prize_regions

has_one :ignindex

end
