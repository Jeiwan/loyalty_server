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

ActiveRecord::Schema.define(version: 20150707044749) do

  create_table "cashbox_operations", force: :cascade do |t|
    t.integer  "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "cashbox_operations", ["number"], name: "index_cashbox_operations_on_number"
  add_index "cashbox_operations", ["user_id"], name: "index_cashbox_operations_on_user_id"

  create_table "loyalty_cards", force: :cascade do |t|
    t.string   "number"
    t.integer  "status",                              default: 0
    t.decimal  "balance",    precision: 10, scale: 2, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "loyalty_certificates", force: :cascade do |t|
    t.string   "number"
    t.integer  "status",      default: 0
    t.string   "card_number"
    t.integer  "pin_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loyalty_certificates", ["card_number"], name: "index_loyalty_certificates_on_card_number"
  add_index "loyalty_certificates", ["number"], name: "index_loyalty_certificates_on_number"
  add_index "loyalty_certificates", ["status"], name: "index_loyalty_certificates_on_status"

  create_table "loyalty_gift_categories", force: :cascade do |t|
    t.integer  "gift_id"
    t.integer  "number"
    t.decimal  "threshold",  precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loyalty_gift_categories", ["gift_id"], name: "index_loyalty_gift_categories_on_gift_id"

  create_table "loyalty_gift_positions", force: :cascade do |t|
    t.integer  "gift_id"
    t.integer  "gift_category_id"
    t.string   "product_uuid",     limit: 36
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loyalty_gift_positions", ["gift_category_id"], name: "index_loyalty_gift_positions_on_gift_category_id"
  add_index "loyalty_gift_positions", ["gift_id"], name: "index_loyalty_gift_positions_on_gift_id"
  add_index "loyalty_gift_positions", ["product_uuid"], name: "index_loyalty_gift_positions_on_product_uuid"

  create_table "loyalty_gifts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "loyalty_purchase_positions", force: :cascade do |t|
    t.string   "uuid",          limit: 36
    t.string   "purchase_uuid", limit: 36
    t.string   "product_uuid",  limit: 36
    t.integer  "quantity"
    t.decimal  "price",                    precision: 10, scale: 2
    t.decimal  "sum",                      precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loyalty_purchase_positions", ["product_uuid"], name: "index_loyalty_purchase_positions_on_product_uuid"
  add_index "loyalty_purchase_positions", ["purchase_uuid"], name: "index_loyalty_purchase_positions_on_purchase_uuid"
  add_index "loyalty_purchase_positions", ["uuid"], name: "index_loyalty_purchase_positions_on_uuid", unique: true

  create_table "loyalty_purchases", force: :cascade do |t|
    t.string   "uuid",               limit: 36
    t.string   "card_number"
    t.decimal  "sum",                           precision: 10, scale: 2
    t.decimal  "paid_by_bonus",                 precision: 10, scale: 2
    t.string   "cashbox"
    t.string   "pharmacy_uuid",      limit: 36
    t.string   "receipt_uuid",       limit: 36
    t.boolean  "is_return",                                              default: false
    t.integer  "status",                                                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "certificate_number"
    t.integer  "user_id"
  end

  add_index "loyalty_purchases", ["card_number"], name: "index_loyalty_purchases_on_card_number"
  add_index "loyalty_purchases", ["certificate_number"], name: "index_loyalty_purchases_on_certificate_number"
  add_index "loyalty_purchases", ["pharmacy_uuid"], name: "index_loyalty_purchases_on_pharmacy_uuid"
  add_index "loyalty_purchases", ["receipt_uuid"], name: "index_loyalty_purchases_on_receipt_uuid"
  add_index "loyalty_purchases", ["status"], name: "index_loyalty_purchases_on_status"
  add_index "loyalty_purchases", ["user_id"], name: "index_loyalty_purchases_on_user_id"

  create_table "loyalty_transactions", force: :cascade do |t|
    t.string   "uuid",          limit: 36
    t.string   "card_number"
    t.string   "purchase_uuid"
    t.integer  "kind"
    t.decimal  "sum",                      precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loyalty_transactions", ["card_number"], name: "index_loyalty_transactions_on_card_number"
  add_index "loyalty_transactions", ["kind"], name: "index_loyalty_transactions_on_kind"
  add_index "loyalty_transactions", ["purchase_uuid"], name: "index_loyalty_transactions_on_purchase_uuid"
  add_index "loyalty_transactions", ["uuid"], name: "index_loyalty_transactions_on_uuid"

  create_table "pharmacies", force: :cascade do |t|
    t.string   "uuid"
    t.string   "name"
    t.integer  "code"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "single_access_token", limit: 18
  end

  add_index "pharmacies", ["uuid"], name: "index_pharmacies_on_uuid"

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "uuid", limit: 36
  end

  add_index "products", ["uuid"], name: "index_products_on_uuid"

  create_table "receipts", force: :cascade do |t|
    t.integer  "cashbox_operation_id"
    t.string   "uuid"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "receipts", ["cashbox_operation_id"], name: "index_receipts_on_cashbox_operation_id"
  add_index "receipts", ["uuid"], name: "index_receipts_on_uuid"

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
