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
  column(:edit, header: "", html: true) do |watchset|
    link_to "Edit", edit_watchset_path(watchset)
  end
end
