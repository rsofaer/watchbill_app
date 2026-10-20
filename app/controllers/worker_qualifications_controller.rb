class WorkerQualificationsController < ApplicationController
  before_action :set_worker

  def create
    worker_qualification = @worker.worker_qualifications.build(
      qualification_id: params.expect(worker_qualification: :qualification_id).fetch(:qualification_id)
    )
    if worker_qualification.save
      flash[:notice] = "Added #{worker_qualification.qualification.name}."
    else
      flash[:error] = "Could not add qualification: #{worker_qualification.errors.full_messages.to_sentence}."
    end
    redirect_to @worker
  end

  def destroy
    worker_qualification = @worker.worker_qualifications.find(params.fetch(:id))
    worker_qualification.destroy!
    flash[:notice] = "Removed #{worker_qualification.qualification.name}."
    redirect_to @worker
  end

  protected

  def set_worker
    @worker = Worker.find(params.fetch(:worker_id))
  end
end
