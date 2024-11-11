class AddAnswerTimeToBookComments < ActiveRecord::Migration[6.1]
  def change
    add_column :book_comments, :answer_time, :decimal, precision: 6, scale: 3
  end
end
