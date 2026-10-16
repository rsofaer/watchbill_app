class Watchstation < ApplicationRecord
  belongs_to :watchset
  belongs_to :qualification
end
