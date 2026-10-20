class WatchsetsGrid < ApplicationGrid

  scope do
    Watchset
  end

  filter(:name, :string)
  filter(:created_at, :date, range: true)

  column(:name) do |watchset|
    format(watchset.name) do |name|
      link_to name, watchset_path(watchset)
    end
  end
  date_column(:created_at)
end
