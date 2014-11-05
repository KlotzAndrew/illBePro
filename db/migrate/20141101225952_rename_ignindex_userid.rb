class RenameIgnindexUserid < ActiveRecord::Migration
  
  def change
  	rename_column :ignindices, :owner_id, :user_id
  end

end
