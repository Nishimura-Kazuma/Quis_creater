class AddPositionToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :position, :integer
  end
end
