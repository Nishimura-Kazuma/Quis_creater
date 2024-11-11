class AddUserIdToQuiztionCollection < ActiveRecord::Migration[6.1]
  def change
    add_column :quiz_collections, :user_id, :integer
  end
end
