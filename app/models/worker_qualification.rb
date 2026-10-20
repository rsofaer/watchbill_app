class WorkerQualification < ApplicationRecord
  belongs_to :worker
  belongs_to :qualification

  validates :qualification, uniqueness: { scope: :worker }
end
