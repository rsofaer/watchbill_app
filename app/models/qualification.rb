class Qualification < ApplicationRecord
  has_many :worker_qualifications
  has_many :workers, through: :worker_qualifications
end
