class WatchbillsGrid < ApplicationGrid
  scope do
    Watchbill.order(created_at: :desc)
  end

  column(:id, header: "Watchbill", html: true) do |watchbill|
    link_to "Watchbill ##{watchbill.id}", watchbill_path(watchbill)
  end
  date_column(:created_at, header: "Saved on")
  boolean_column(:properly_staffed?, header: "Valid", order: false)
end
