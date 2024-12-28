# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_28_161134) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street", null: false
    t.string "city", null: false
    t.string "postal_code"
    t.string "country", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_addresses_on_company_id"
  end

  create_table "authentication_tokens", force: :cascade do |t|
    t.string "body"
    t.bigint "user_id", null: false
    t.datetime "last_used_at"
    t.integer "expires_in"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "body" ], name: "index_authentication_tokens_on_body"
    t.index [ "user_id" ], name: "index_authentication_tokens_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", limit: 256, null: false
    t.integer "registration_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "registration_number" ], name: "index_companies_on_registration_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_users_on_email", unique: true
  end

  add_foreign_key "addresses", "companies"
  add_foreign_key "authentication_tokens", "users"
end
