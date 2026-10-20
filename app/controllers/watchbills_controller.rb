class WatchbillsController < ApplicationController
  def index
    @watchset = Watchset.find(params.fetch(:watchset_id))
    @grid = WatchbillsGrid.new(grid_params) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  def show
    @watchbill = Watchbill.find(params.fetch(:id))
    @watchset = @watchbill.watchset
    @grid = WatchsetGrid.new(watchbill: @watchbill) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  def create
    watchset = Watchset.find(params.fetch(:watchset_id))
    watchbill = watchset.watchbills.build(watchbill_params)
    if watchbill.save
      flash[:notice] = "Watchbill saved."
      redirect_to watchbill
    else
      flash[:error] = "Watchbill could not be saved: #{watchbill.errors.full_messages.to_sentence}"
      redirect_to watchset
    end
  end

  protected

  def grid_params
    params.fetch(:watchbills_grid, {}).permit!
  end

  def watchbill_params
    params.fetch(:watchbill, {})
      .permit(watchbill_station_assignments_attributes: [ :watchstation_id, :shift, :worker_id ])
  end
end
