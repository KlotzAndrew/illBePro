class Status < ActiveRecord::Base
  validates :ignindex_id, presence: true
  validate :dr_who, :on => :create
  validate :one_fox_one_gun, :on => :create

  belongs_to :ignindex

  serialize :game_1, Hash
  serialize :game_2, Hash
  serialize :game_3, Hash
  serialize :game_4, Hash
  serialize :game_5, Hash

  def factory_test
    Rails.logger.info "User.all.count:: #{User.all.count}"
    self.update(summoner_name: "working")
  end


  def dr_who #this makes sure summoner is valid + region is entered
    ignindex = self.ignindex
    if ignindex.summoner_validated != true
      errors.add(:summoner_required, '- You need a summoner name before you can start a challenge!')
    elsif ignindex.region_id.nil?
      errors.add(:region_required, '- You need to select a prize zone to start a challenge')
    end
  end

  def one_fox_one_gun #this is 1 game/user + concurrent requests/API
    ignindex = self.ignindex
    if ignindex.statuses.where("win_value IS ?", nil).count > 0
      errors.add(:you_can, 'only have 1 challenge running at a time!')
    elsif Status.all.where("created_at >= ?", Time.now - 60.seconds).count > 19
      errors.add(:start_queue, ' is full! Try back in 60 seconds')
    else
      Rails.logger.info "no errors"
    end
  end
end