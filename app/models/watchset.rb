class Watchset < ApplicationRecord
  has_many :watchstations
  has_many :qualifications, through: :watchstation
end
