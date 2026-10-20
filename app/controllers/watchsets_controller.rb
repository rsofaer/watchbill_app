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
      redirect_to watchsets_path
      return
    end

    @watchbill = @watchset.generate_watchbill
    unless @watchbill.is_a?(Watchbill)
      flash.now[:error] = "No valid watchbill could be generated for this watchset."
      @watchbill = @watchset.watchbills.build
    end
    @grid = WatchsetGrid.new(grid_params.merge(watchbill: @watchbill)) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  protected

  def grid_params
    params.fetch(:watchsets_grid, {}).permit!
  end
end
