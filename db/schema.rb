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

ActiveRecord::Schema[7.1].define(version: 2023_12_02_191737) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "offers", force: :cascade do |t|
    t.bigint "offerer_id", null: false
    t.bigint "pair_request_id", null: false
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "period_id", null: false
    t.datetime "accepted_at"
    t.index ["offerer_id", "pair_request_id"], name: "index_offers_on_offerer_id_and_pair_request_id", unique: true
    t.index ["offerer_id"], name: "index_offers_on_offerer_id"
    t.index ["pair_request_id"], name: "index_offers_on_pair_request_id"
  end

  create_table "pair_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.string "subject", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration", null: false
    t.index ["user_id"], name: "index_pair_requests_on_user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.string "participable_type", null: false
    t.bigint "participable_id", null: false
    t.bigint "participant_id", null: false
    t.string "role", null: false
    t.index ["participable_type", "participable_id"], name: "index_participations_on_participable"
    t.index ["participant_id"], name: "index_participations_on_participant_id"
  end

  create_table "periods", force: :cascade do |t|
    t.string "periodable_type", null: false
    t.bigint "periodable_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["periodable_type", "periodable_id"], name: "index_periods_on_periodable"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "sessionable_type", null: false
    t.bigint "sessionable_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sessionable_type", "sessionable_id"], name: "index_sessions_on_sessionable"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "offers", "pair_requests"
  add_foreign_key "offers", "users", column: "offerer_id"
  add_foreign_key "pair_requests", "users"
  add_foreign_key "participations", "users", column: "participant_id"
end
