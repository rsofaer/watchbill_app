class Qualification < ApplicationRecord
  has_many :workers, through: :worker_qualification
end
