class WatchbillsController < ApplicationController
  def index
    @grid = WatchbillsGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @watchbill = Watchbill.includes(watchbill_station_assignments: [:watchstation, { worker: :qualifications }])
      .find_by(id: params[:id])
    if not @watchbill
      flash[:error] = "Watchbill not found."
      redirect_to watchbills_path
      return
    end

    @problems = @watchbill.problems
    @grid = WatchsetGrid.new(params.fetch(:watchset_grid, {}).permit!.merge(watchbill: @watchbill)) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchbill.watchset)
    end
  end

  def create
    @watchset = Watchset.find_by(id: params[:watchset_id])
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
      return
    end

    @watchbill = @watchset.watchbills.build(watchbill_params)
    if @watchbill.save
      flash[:notice] = "Watchbill saved."
      redirect_to watchbill_path(@watchbill)
    else
      flash[:error] = "Watchbill could not be saved: #{@watchbill.errors.full_messages.to_sentence}"
      redirect_to watchset_path(@watchset)
    end
  end

  protected

  def grid_params
    params.fetch(:watchbills_grid, {}).permit!
  end

  def watchbill_params
    params.fetch(:watchbill, {}).permit(watchbill_station_assignments_attributes: [:watchstation_id, :shift, :worker_id])
  end
end
