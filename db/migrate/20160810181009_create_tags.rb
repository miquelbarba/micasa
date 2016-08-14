class CreateTags < ActiveRecord::Migration[5.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :flat_id
      t.timestamps
    end

    add_foreign_key :tags, :flats
  end
end
