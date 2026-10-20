class WorkersGrid < ApplicationGrid

  scope do
    Worker.includes(:qualifications)
  end

  column(:name, html: ->(name, worker) { link_to name, worker_path(worker) })
  column(:qualifications, order: false) do |worker|
    worker.qualifications.map(&:name).sort.join(", ")
  end
end
