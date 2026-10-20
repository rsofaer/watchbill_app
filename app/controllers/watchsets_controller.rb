class WatchsetsController < ApplicationController
  before_action :set_watchset, only: [:show, :edit, :update]

  def index
    @grid = WatchsetsGrid.new(grid_params(:watchsets_grid)) do |scope|
      scope.page(params[:page])
    end
  end

  def show
    @watchbill = @watchset.generate_watchbill
    if not @watchbill
      flash.now[:error] = "No valid watchbill exists for this watchset."
      @watchbill = @watchset.watchbills.build
    end
    @grid = WatchsetGrid.new(grid_params(:watchset_grid).merge(watchbill: @watchbill)) do |scope|
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

  def grid_params(key)
    params.fetch(key, {}).permit!
  end
end
