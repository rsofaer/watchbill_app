class Worker < ApplicationRecord
  has_many :qualifications, through: :worker_qualification
end
