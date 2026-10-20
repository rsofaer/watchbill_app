class WatchsetsGrid < ApplicationGrid

  scope do
    Watchset
  end

  filter(:name, :integer)
  filter(:created_at, :date, range: true)

  column(:name)
  date_column(:created_at)
  column(:edit, header: "", html: true) do |watchset|
    link_to "Edit", edit_watchset_path(watchset)
  end
end
