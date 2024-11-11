class CreateQuizCollections < ActiveRecord::Migration[6.1]
  def change
    create_table :quiz_collections do |t|

      t.timestamps
    end
  end
end
