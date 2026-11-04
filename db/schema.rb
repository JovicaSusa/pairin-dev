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

ActiveRecord::Schema[7.1].define(version: 2026_11_04_210000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.text "content"
    t.bigint "receiver_id", null: false
    t.string "title"
    t.datetime "seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_activities_on_receiver_id"
  end

  create_table "availability_windows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "weekday", null: false
    t.integer "start_minute", null: false
    t.integer "end_minute", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_availability_windows_on_user_id"
    t.exclusion_constraint "user_id WITH =, weekday WITH =, int4range(start_minute, end_minute) WITH &&", using: :gist, name: "availability_windows_no_overlap"
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "offer_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id", "created_at"], name: "index_messages_on_offer_id_and_created_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "offers", force: :cascade do |t|
    t.bigint "offerer_id", null: false
    t.bigint "pair_request_id", null: false
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "accepted_at"
    t.datetime "expiry_notified_at"
    t.text "goal"
    t.string "how_often"
    t.string "how_long"
    t.datetime "replied_at"
    t.datetime "last_message_at"
    t.datetime "ended_at"
    t.bigint "ended_by_id"
    t.text "end_reason"
    t.datetime "poster_read_at"
    t.datetime "offerer_read_at"
    t.datetime "poster_emailed_at"
    t.datetime "offerer_emailed_at"
    t.datetime "proposed_at"
    t.bigint "proposed_by_id"
    t.datetime "proposal_declined_at"
    t.index ["ended_by_id"], name: "index_offers_on_ended_by_id"
    t.index ["last_message_at"], name: "index_offers_on_last_message_at"
    t.index ["offerer_id", "pair_request_id"], name: "index_offers_on_offerer_id_and_pair_request_id", unique: true
    t.index ["offerer_id"], name: "index_offers_on_offerer_id"
    t.index ["proposed_by_id"], name: "index_offers_on_proposed_by_id"
    t.index ["pair_request_id"], name: "index_offers_on_pair_request_id"
  end

  create_table "pair_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "description", null: false
    t.string "subject", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "paused_at"
    t.string "commitment", default: "one_to_three_months", null: false
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

  create_table "partnerships", force: :cascade do |t|
    t.bigint "offer_id", null: false
    t.bigint "pair_request_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id"], name: "index_partnerships_on_offer_id", unique: true
    t.index ["pair_request_id"], name: "index_partnerships_on_pair_request_id", unique: true
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
    t.text "call_link"
    t.index ["sessionable_type", "sessionable_id"], name: "index_sessions_on_sessionable"
  end

  create_table "taggings", force: :cascade do |t|
    t.string "taggable_type", null: false
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "language"
    t.text "about"
    t.string "country"
    t.date "date_of_birth"
    t.string "level"
    t.integer "programming_since"
    t.text "image_data"
    t.string "name"
    t.string "profession"
    t.string "timezone", default: "UTC", null: false
    t.string "github_url"
    t.datetime "suspended_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["country"], name: "index_users_on_country"
    t.index ["date_of_birth"], name: "index_users_on_date_of_birth"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["language"], name: "index_users_on_language"
    t.index ["programming_since"], name: "index_users_on_programming_since"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended_at"], name: "index_users_on_suspended_at"
  end

  add_foreign_key "activities", "users", column: "receiver_id"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "messages", "offers"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "offers", "users", column: "ended_by_id"
  add_foreign_key "offers", "users", column: "proposed_by_id"
  add_foreign_key "partnerships", "offers"
  add_foreign_key "partnerships", "pair_requests"
  add_foreign_key "availability_windows", "users"
  add_foreign_key "offers", "pair_requests"
  add_foreign_key "offers", "users", column: "offerer_id"
  add_foreign_key "pair_requests", "users"
  add_foreign_key "participations", "users", column: "participant_id"
  add_foreign_key "taggings", "tags"
end
