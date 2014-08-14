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

ActiveRecord::Schema.define(version: 20110208155312) do

  create_table "bastards", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "change_hoarders", force: true do |t|
    t.integer "draft_id"
  end

  create_table "children", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clingy_parents", force: true do |t|
    t.string   "name"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "draft_as_sketches", force: true do |t|
    t.string   "name"
    t.integer  "sketch_id"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "draft_dependencies", force: true do |t|
    t.integer "draft_id",      null: false
    t.integer "dependency_id", null: false
  end

  create_table "draft_dependents", force: true do |t|
    t.integer "draft_id",     null: false
    t.integer "dependent_id", null: false
  end

  create_table "drafts", force: true do |t|
    t.string   "item_type"
    t.integer  "item_id"
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.text     "object_changes"
    t.text     "previous_draft"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "answer"
    t.string   "ip"
    t.string   "user_agent"
  end

  create_table "hopeless_children", force: true do |t|
    t.string   "name"
    t.integer  "clingy_parent_id"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mortgages", force: true do |t|
    t.float    "amount"
    t.integer  "parent_id"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "parents", force: true do |t|
    t.string   "name"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "skippers", force: true do |t|
    t.string   "name"
    t.string   "skip_me"
    t.integer  "draft_id"
    t.datetime "trashed_at"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trashables", force: true do |t|
    t.string   "name"
    t.string   "title"
    t.integer  "draft_id"
    t.datetime "published_at"
    t.datetime "trashed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vanillas", force: true do |t|
    t.string   "name"
    t.integer  "draft_id"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "whitelisters", force: true do |t|
    t.string   "name"
    t.string   "ignored"
    t.integer  "draft_id"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
