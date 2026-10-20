class Worker < ApplicationRecord
  has_many :worker_qualifications, dependent: :destroy
  has_many :qualifications, through: :worker_qualifications

  validates :name, presence: true
end
