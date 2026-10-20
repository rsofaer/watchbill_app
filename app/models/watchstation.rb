class Watchstation < ApplicationRecord
  belongs_to :watchset
  belongs_to :qualification

  validates :name, presence: true
end
