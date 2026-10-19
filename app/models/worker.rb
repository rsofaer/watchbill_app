class Worker < ApplicationRecord
  has_many :worker_qualifications
  has_many :qualifications, through: :worker_qualifications
end
