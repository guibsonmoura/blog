class Reaction < ApplicationRecord
  belongs_to :post

  enum :reaction_type, { like: 0, heart: 1, haha: 2, wow: 3, sad: 4, fire: 5 }

  validates :session_id, presence: true,
                         uniqueness: { scope: [ :post_id, :reaction_type ] }
end
