class BookComment < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :comment, presence: true
  validates :answer_time, presence: true
  
  def correct?
    self.comment == book.correct_answer
  end
  
end
