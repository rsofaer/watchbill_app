class WatchsetsController < ApplicationController
  def index
    @grid = WatchsetsGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @watchset = Watchset.find_by(id: params[:id])
    if not @watchset
      flash[:error] = "Watchset not found."
      return redirect_to watchsets_path
    end

    @watchbill = @watchset.generate_watchbill || Watchbill.new
    @grid = WatchsetGrid.new(watchset_grid_params.merge(watchbill: @watchbill)) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  protected

  def grid_params
    params.fetch(:watchsets_grid, {}).permit!
  end

  def watchset_grid_params
    params.fetch(:watchset_grid, {}).permit!
  end
end
