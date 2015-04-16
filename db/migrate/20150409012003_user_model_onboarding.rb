class UserModelOnboarding < ActiveRecord::Migration
  def change
  	add_column :users, :setup_progress, :integer, default: 0
  end
end
