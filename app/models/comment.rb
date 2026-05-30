class Comment < ApplicationRecord
  belongs_to :post

  validates :author_name, presence: true
  validates :body, presence: true, length: { maximum: 2000 }
end
