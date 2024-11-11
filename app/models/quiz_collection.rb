class QuizCollection < ApplicationRecord
    has_many :books, dependent: :destroy
    belongs_to :user
    validates :title, presence: true
end
