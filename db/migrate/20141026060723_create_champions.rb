class CreateChampions < ActiveRecord::Migration
  def change
    create_table :champions do |t|
      t.string :champion

      t.timestamps
    end
  end
end
