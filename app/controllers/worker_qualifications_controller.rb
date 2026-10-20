class WorkerQualificationsController < ApplicationController
  before_action :set_worker

  def create
    worker_qualification = @worker.worker_qualifications.build(qualification_id: params.dig(:worker_qualification, :qualification_id))
    if worker_qualification.save
      flash[:notice] = "Added #{worker_qualification.qualification.name} to #{@worker.name}."
    else
      flash[:error] = worker_qualification.errors.full_messages.to_sentence
    end
    redirect_to worker_path(@worker)
  end

  def destroy
    worker_qualification = @worker.worker_qualifications.find_by(id: params[:id])
    if worker_qualification
      worker_qualification.destroy
      flash[:notice] = "Removed #{worker_qualification.qualification.name} from #{@worker.name}."
    else
      flash[:error] = "Qualification not found."
    end
    redirect_to worker_path(@worker)
  end

  protected

  def set_worker
    @worker = Worker.find_by(id: params[:worker_id])
    if not @worker
      flash[:error] = "Worker not found."
      redirect_to workers_path
    end
  end
end
