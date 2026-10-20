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
    end

    @watchbill = @watchset.generate_watchbill
    @grid = WatchsetGrid.new(grid_params.merge(watchbill: @watchbill)) do |scope|
      scope.page(params[:page])
        .where(watchset: @watchset)
    end
  end

  def new
    @watchset = Watchset.new
  end

  def create
    @watchset = Watchset.new(watchset_params)
    if @watchset.save
      flash[:notice] = "Watchset created. Add its watchstations below."
      redirect_to edit_watchset_path(@watchset)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @watchset = Watchset.find_by(id: params.fetch(:id))
    @watchstation = Watchstation.new
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
    end
  end

  protected

  def grid_params
    params.fetch(:watchsets_grid, {}).permit!
  end

  def watchset_params
    params.require(:watchset).permit(:name)
  end
end
