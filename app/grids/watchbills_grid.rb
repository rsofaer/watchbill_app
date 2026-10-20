class WatchbillsGrid < ApplicationGrid

  scope do
    Watchbill.includes(:watchset).order(created_at: :desc)
  end

  column(:id, header: "Watchbill", html: true) do |watchbill|
    link_to "Watchbill ##{watchbill.id}", watchbill_path(watchbill)
  end
  column(:watchset, header: "Watchset") do |watchbill|
    watchbill.watchset.name
  end
  date_column(:created_at, header: "Saved")
  boolean_column(:valid_watchbill?, header: "Currently Valid")
end
