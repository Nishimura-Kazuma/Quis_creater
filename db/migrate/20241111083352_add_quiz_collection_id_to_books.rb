class AddQuizCollectionIdToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :quiz_collection_id, :integer
  end
end
