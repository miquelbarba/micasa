class CreateFlat < ActiveRecord::Migration[5.0]
  def change
    create_table :flats do |t|
      t.string :title, size: 512
      t.string :neighbourhood
      t.string :district
      t.integer :price
      t.string :postal_code
      t.integer :rooms
      t.integer :baths
      t.integer :sq_meters
      t.string :conservation
      t.integer :floor
      t.decimal :lat, scale: 6, precision: 10
      t.decimal :lng, scale: 6, precision: 10
      t.string :url, size: 1024
      t.string :external_id
      t.datetime :last_visit
      t.text :json
      t.string :image_url, size: 1024
      t.string :portal
      t.integer :price_sq_meter

      t.timestamps
    end
  end
end
