class AddChoicesCountAndChoicesToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :choices_count, :integer
  end
end
