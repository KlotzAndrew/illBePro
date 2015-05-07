class PrizeRegion < ActiveRecord::Base
	belongs_to :region 
	belongs_to :prize 

end