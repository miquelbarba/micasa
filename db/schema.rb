# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160810203532) do

  create_table "flats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "title"
    t.string   "neighbourhood"
    t.string   "district"
    t.integer  "price"
    t.string   "postal_code"
    t.integer  "rooms"
    t.integer  "baths"
    t.integer  "sq_meters"
    t.string   "conservation"
    t.integer  "floor"
    t.decimal  "lat",                          precision: 10, scale: 6
    t.decimal  "lng",                          precision: 10, scale: 6
    t.string   "url"
    t.string   "external_id"
    t.datetime "last_visit"
    t.text     "json",           limit: 65535
    t.string   "image_url"
    t.string   "portal"
    t.integer  "price_sq_meter"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  create_table "prices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "price"
    t.integer  "flat_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flat_id"], name: "fk_rails_c6b3611dcf", using: :btree
  end

  create_table "tags", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "flat_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flat_id"], name: "fk_rails_d67975fad3", using: :btree
  end

  add_foreign_key "prices", "flats"
  add_foreign_key "tags", "flats"
end
