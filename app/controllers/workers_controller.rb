class WorkersController < ApplicationController
  def index
    @grid = WorkersGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @worker = Worker.find(params.fetch(:id))
    @available_qualifications = Qualification.where.not(id: @worker.qualification_ids).order(:name)
  end

  def new
    @worker = Worker.new
  end

  def create
    @worker = Worker.new(worker_params)
    if @worker.save
      flash[:notice] = "Added #{@worker.name}."
      redirect_to @worker
    else
      render :new, status: :unprocessable_content
    end
  end

  protected

  def worker_params
    params.expect(worker: :name)
  end

  def grid_params
    params.fetch(:workers_grid, {}).permit!
  end
end
