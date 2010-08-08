# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 8) do

  create_table "expenses", :force => true do |t|
    t.string  "name"
    t.date    "datum"
    t.float   "netto"
    t.float   "brutto"
    t.float   "mwst"
    t.string  "art"
    t.boolean "bezahlt"
    t.boolean "abgerechnet",   :default => false
    t.date    "eintragsdatum"
    t.boolean "geloescht",     :default => false
    t.integer "user_id"
    t.integer "statement_id"
  end

  create_table "gains", :force => true do |t|
    t.string  "name"
    t.date    "datum"
    t.float   "netto"
    t.float   "brutto"
    t.float   "mwst"
    t.boolean "bezahlt"
    t.boolean "abgerechnet",   :default => false
    t.date    "eintragsdatum"
    t.boolean "geloescht",     :default => false
    t.integer "user_id"
    t.integer "statement_id"
  end

  create_table "statements", :force => true do |t|
    t.string "name"
    t.date   "erstellungsdatum"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
