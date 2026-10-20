class WatchsetsController < ApplicationController
  before_action :set_watchset, only: [:show, :edit, :update]

  def index
    @grid = WatchsetsGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    # generate_watchbill returns nil when the watchset has no stations or
    # workers, and an unsat core when no valid watchbill exists.
    watchbill = @watchset.generate_watchbill
    @watchbill = watchbill if watchbill.is_a?(Watchbill)
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
      flash[:notice] = "Watchset created. Add watchstations below."
      redirect_to edit_watchset_path(@watchset)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @watchstation = @watchset.watchstations.build
  end

  def update
    if @watchset.update(watchset_params)
      flash[:notice] = "Watchset renamed."
      redirect_to edit_watchset_path(@watchset)
    else
      @watchstation = @watchset.watchstations.build
      render :edit, status: :unprocessable_entity
    end
  end

  protected

  def set_watchset
    @watchset = Watchset.find_by(id: params[:id])
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
    end
  end

  def watchset_params
    params.require(:watchset).permit(:name)
  end

  def grid_params
    params.fetch(:watchsets_grid, {}).permit!
  end
end
