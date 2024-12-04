class AddCorrectAnswerToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :correct_answer, :string
  end
end
