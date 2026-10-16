class CreateWorkers < ActiveRecord::Migration[8.1]
  def change
    create_table :workers do |t|
      t.timestamps
      t.string "name"
    end

    create_table :qualifications do |t|
      t.timestamps
      t.string "name"
    end

    create_table :watchsets do |t|
      t.timestamps
      t.string "name"
    end

    create_table :watchstations do |t|
      t.timestamps
      t.string "name"
      
      t.references :watchset
      t.references :qualification
    end

    create_table :worker_qualifications do |t|
      t.timestamps

      t.references :qualification
      t.references :worker
    end
  end
end
