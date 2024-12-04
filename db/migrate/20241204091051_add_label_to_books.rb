class AddLabelToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :label, :string, null: true
  end
end
