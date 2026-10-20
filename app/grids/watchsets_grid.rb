class WatchsetsGrid < ApplicationGrid

  scope do
    Watchset
  end

  filter(:name, :string)
  filter(:created_at, :date, range: true)

  column(:name, html: true) do |watchset|
    link_to watchset.name, watchset_path(watchset)
  end
  date_column(:created_at)
  column(:actions, header: "", html: true) do |watchset|
    link_to "Edit", edit_watchset_path(watchset), class: "btn btn-sm btn-outline-secondary"
  end
end
