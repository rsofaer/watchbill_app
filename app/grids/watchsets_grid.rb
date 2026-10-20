class WatchsetsGrid < ApplicationGrid

  scope do
    Watchset
  end

  filter(:name, :integer)
  filter(:created_at, :date, range: true)

  column(:name, html: true) do |watchset|
    link_to watchset.name, watchset_path(watchset)
  end
  date_column(:created_at)
end
