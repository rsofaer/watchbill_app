class WatchstationsController < ApplicationController
  before_action :set_watchset

  def create
    @watchstation = @watchset.watchstations.build(watchstation_params)
    if @watchstation.save
      flash[:notice] = "Added #{@watchstation.name}."
      redirect_to edit_watchset_path(@watchset)
    else
      render "watchsets/edit", status: :unprocessable_entity
    end
  end

  def destroy
    watchstation = @watchset.watchstations.find_by(id: params[:id])
    if watchstation
      watchstation.destroy
      flash[:notice] = "Removed #{watchstation.name}."
    else
      flash[:error] = "Watchstation not found."
    end
    redirect_to edit_watchset_path(@watchset)
  end

  protected

  def set_watchset
    @watchset = Watchset.find_by(id: params[:watchset_id])
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
    end
  end

  def watchstation_params
    params.require(:watchstation).permit(:name, :qualification_id)
  end
end
