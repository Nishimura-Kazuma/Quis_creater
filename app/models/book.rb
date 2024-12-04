class Book < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_collection
  has_many :favorites, dependent: :destroy
  has_many :book_comments, dependent: :destroy
  
  validates :title, presence: true
  validates :body, presence: true
  validates :quiz_collection, presence: true
  validates :choices_count, presence: true
  has_one_attached :image
  
  # デフォルトの position を設定
  before_create :set_default_position
  after_initialize :set_default_values, if: :new_record?

  def set_default_position
    if quiz_collection.present?
      self.position ||= quiz_collection.books.maximum(:position).to_i + 1
    else
      self.position = 1
    end
  end
  
  def favorited_by?(user)
    favorites.exists?(user_id: user.id)
  end
  
  def get_image(width, height)
    unless image.attached?
      file_path = Rails.root.join('app/assets/images/default-image.jpg')
      image.attach(io: File.open(file_path), filename: 'default-image.jpg', content_type: 'image/jpeg')
    end
    image.variant(resize_to_limit: [width, height]).processed
  end
  
  def next_book
    quiz_collection.books.where("position > ?", position).order(:position).first
  end
  
  def set_default_values
    self.include_in_export = true if include_in_export.nil?
  end
  
end
