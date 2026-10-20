class WatchsetsController < ApplicationController
  def index
    @grid = WatchsetsGrid.new(grid_params(:watchsets_grid)) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @watchset = Watchset.find_by(id: params[:id])
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
      return
    end

    @watchbill = @watchset.generate_watchbill
    if not @watchbill
      flash.now[:error] = "No valid watchbill exists for this watchset."
    end
    @grid = WatchsetGrid.new(grid_params(:watchset_grid).merge(watchbill: @watchbill)) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  protected

  def grid_params(key)
    params.fetch(key, {}).permit!
  end
end
