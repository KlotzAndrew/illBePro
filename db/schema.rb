# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150409012003) do

  create_table "champions", force: true do |t|
    t.string   "champion"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geodelivers", force: true do |t|
    t.integer  "user_id"
    t.string   "ip_address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "country_code"
    t.string   "postal_code"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "city"
    t.integer  "region_id"
  end

  create_table "ignindices", force: true do |t|
    t.integer  "user_id"
    t.string   "summoner_name"
    t.integer  "summoner_id"
    t.boolean  "summoner_validated"
    t.string   "validation_string"
    t.integer  "validation_timer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mastery_1_name"
    t.string   "summoner_name_ref"
    t.integer  "prize_level",        default: 0
    t.integer  "challenge_points_1", default: 0
    t.integer  "challenge_points_2", default: 0
    t.integer  "challenge_points_3", default: 0
    t.integer  "last_prize_time",    default: 0
    t.integer  "prize_token"
  end

  create_table "prizes", force: true do |t|
    t.string   "description"
    t.string   "tier"
    t.string   "vendor"
    t.integer  "code"
    t.integer  "assignment"
    t.integer  "user_id"
    t.string   "summoner_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "geo"
    t.string   "region_id"
    t.integer  "delivered_at"
    t.string   "country_zone"
    t.string   "province_zone"
    t.string   "reward_code"
  end

  create_table "regions", force: true do |t|
    t.string   "postal_code"
    t.string   "city"
    t.float    "lat"
    t.float    "long"
    t.string   "country"
    t.string   "province"
    t.string   "active"
    t.string   "vendor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prize_id_tier1"
    t.string   "prize_id_tier2"
    t.string   "prize_id_tier3"
    t.string   "prize_id_tier4"
  end

  create_table "scores", force: true do |t|
    t.integer  "user_id"
    t.string   "summoner_name"
    t.integer  "summoner_id"
    t.integer  "week_1"
    t.integer  "week_2"
    t.integer  "week_3"
    t.integer  "week_4"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "week_5",           default: 0
    t.integer  "week_6",           default: 0
    t.integer  "week_7",           default: 0
    t.integer  "week_8",           default: 0
    t.integer  "week_9",           default: 0
    t.integer  "week_10",          default: 0
    t.integer  "week_11",          default: 0
    t.integer  "prize_level",      default: 1
    t.integer  "challenge_points", default: 0
    t.integer  "last_prize_time",  default: 0
    t.integer  "prize_id"
  end

  create_table "statuses", force: true do |t|
    t.text     "content"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "summoner_id"
    t.string   "summoner_name"
    t.integer  "kind"
    t.integer  "points"
    t.string   "challenge_description"
    t.integer  "win_value"
    t.integer  "api_ping"
    t.text     "game_1"
    t.text     "game_2"
    t.text     "game_3"
    t.text     "game_4"
    t.text     "game_5"
    t.integer  "pause_timer"
    t.integer  "trigger_timer"
    t.integer  "prize_id"
    t.integer  "proc_value",            default: 0
    t.integer  "roll_status",           default: 0
  end

  add_index "statuses", ["user_id"], name: "index_statuses_on_user_id"

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "profile_name"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "summoner_id"
    t.string   "summoner_name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "setup_progress",         default: 0
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
