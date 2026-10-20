class WorkerQualification < ApplicationRecord
  belongs_to :worker
  belongs_to :qualification

  validates :qualification_id, uniqueness: { scope: :worker_id, message: "already held by this worker" }
end
