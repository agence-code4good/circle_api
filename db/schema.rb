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

ActiveRecord::Schema[8.1].define(version: 2026_01_15_133755) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "api_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.string "endpoint", null: false
    t.text "error_backtrace"
    t.text "error_message"
    t.string "http_method", null: false
    t.inet "ip_address"
    t.bigint "order_id"
    t.bigint "partner_id"
    t.string "path"
    t.text "request_body"
    t.jsonb "request_headers", default: {}
    t.string "request_id", null: false
    t.jsonb "request_params", default: {}
    t.jsonb "response_body"
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.jsonb "validation_errors"
    t.boolean "validation_success"
    t.index ["created_at"], name: "index_api_logs_on_created_at"
    t.index ["endpoint", "created_at"], name: "index_api_logs_on_endpoint_and_created_at"
    t.index ["order_id"], name: "index_api_logs_on_order_id"
    t.index ["partner_id", "created_at"], name: "index_api_logs_on_partner_id_and_created_at"
    t.index ["partner_id"], name: "index_api_logs_on_partner_id"
    t.index ["request_id"], name: "index_api_logs_on_request_id"
    t.index ["status_code"], name: "index_api_logs_on_status_code"
    t.index ["validation_success"], name: "index_api_logs_on_validation_success"
  end

  create_table "circle_codes", force: :cascade do |t|
    t.bigint "circle_product_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.index ["circle_product_id", "code"], name: "index_circle_codes_on_circle_product_id_and_code", unique: true
    t.index ["circle_product_id"], name: "index_circle_codes_on_circle_product_id"
    t.index ["code"], name: "index_circle_codes_on_code"
    t.index ["value"], name: "index_circle_codes_on_value", using: :gin
  end

  create_table "circle_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_lines", force: :cascade do |t|
    t.jsonb "circle_code"
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "accompanying_document_url"
    t.string "buyer_id"
    t.datetime "created_at", null: false
    t.date "estimated_availability_earliest_at"
    t.string "initial_order_reference"
    t.date "latest_instruction_due_date"
    t.string "note"
    t.string "order_reference"
    t.integer "previous_status"
    t.string "seller_id"
    t.integer "status"
    t.datetime "updated_at", null: false
  end

  create_table "partners", force: :cascade do |t|
    t.string "auth_token"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "api_logs", "orders"
  add_foreign_key "api_logs", "partners"
  add_foreign_key "circle_codes", "circle_products"
  add_foreign_key "order_lines", "orders"
end
