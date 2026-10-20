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
    create_table :watchbills do |t|
      t.timestamps
      t.references :watchset
    end
    create_table :watchbill_station_assignments do |t|
      t.timestamps
      t.references :watchbill
      t.references :watchstation
      t.references :worker
      t.integer :shift, default: 0
    end
  end
end
