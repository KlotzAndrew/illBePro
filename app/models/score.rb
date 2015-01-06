class Score < ActiveRecord::Base

  after_create :build_scorecard

  def build_scorecard
  	self.update(:week_1 => 0, :week_2 => 0, :week_3 => 0, :week_4 => 0, :week_5 => 0, :week_6 => 0,:week_7 => 0,:week_8 => 0,:week_9 => 0,:week_10 => 0,:week_11 => 0)
  end

end
