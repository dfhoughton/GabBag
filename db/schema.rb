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

ActiveRecord::Schema.define(version: 20140928152259) do

  create_table "anagrams", force: true do |t|
    t.integer  "phrase_id"
    t.integer  "child_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "favored",    default: 0
    t.integer  "shared",     default: 0
  end

  add_index "anagrams", ["child_id"], name: "index_anagrams_on_child_id"
  add_index "anagrams", ["phrase_id"], name: "index_anagrams_on_phrase_id"

  create_table "favorites", force: true do |t|
    t.integer  "user_id"
    t.integer  "anagram_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favorites", ["anagram_id"], name: "index_favorites_on_anagram_id"
  add_index "favorites", ["user_id"], name: "index_favorites_on_user_id"

  create_table "friends", force: true do |t|
    t.integer  "user_id"
    t.integer  "other_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "subscribed", default: false
  end

  add_index "friends", ["other_id"], name: "index_friends_on_other_id"
  add_index "friends", ["user_id"], name: "index_friends_on_user_id"

  create_table "notifications", force: true do |t|
    t.integer  "user_id"
    t.boolean  "received"
    t.boolean  "read"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "body"
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"

  create_table "phrases", force: true do |t|
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "phrases", ["text"], name: "unique_text", unique: true

  create_table "users", force: true do |t|
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
