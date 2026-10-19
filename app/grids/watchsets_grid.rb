class WatchsetsGrid < ApplicationGrid

  scope do
    Watchset
  end

  filter(:name, :integer)
  filter(:created_at, :date, range: true)

  column(:name)
  date_column(:created_at)
end
