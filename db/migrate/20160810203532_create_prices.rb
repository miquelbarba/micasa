class CreatePrices < ActiveRecord::Migration[5.0]
  def change
    create_table :prices do |t|
      t.string :price
      t.integer :flat_id
      t.timestamps
    end

    add_foreign_key :prices, :flats
  end
end
