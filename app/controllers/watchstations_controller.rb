class WatchstationsController < ApplicationController
  before_action :find_watchset

  def create
    @watchstation = Watchstation.new(watchstation_params.merge(watchset: @watchset))
    if @watchstation.save
      flash[:notice] = "Added #{@watchstation.name}."
      redirect_to edit_watchset_path(@watchset)
    else
      render "watchsets/edit", status: :unprocessable_content
    end
  end

  def destroy
    watchstation = @watchset.watchstations.find_by(id: params.fetch(:id))
    if watchstation
      watchstation.destroy!
      flash[:notice] = "Removed #{watchstation.name}."
    else
      flash[:error] = "Watchstation not found."
    end
    redirect_to edit_watchset_path(@watchset)
  end

  protected

  def find_watchset
    @watchset = Watchset.find_by(id: params.fetch(:watchset_id))
    if not @watchset
      flash[:error] = "Watchset not found."
      redirect_to watchsets_path
    end
  end

  def watchstation_params
    params.require(:watchstation).permit(:name, :qualification_id)
  end
end
