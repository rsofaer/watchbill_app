class WatchsetsController < ApplicationController
  def index
    @grid = WatchsetsGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  protected

  def grid_params
    params.fetch(:watchsets_grid, {}).permit!
  end
end
