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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "aberrations", :force => true do |t|
    t.string "aberration_class", :limit => 32, :null => false
    t.text   "aberration",                     :null => false
  end

  create_table "aberrations_breakpoints", :id => false, :force => true do |t|
    t.integer "aberration_id", :null => false
    t.integer "breakpoint_id", :null => false
  end

  add_index "aberrations_breakpoints", ["aberration_id", "breakpoint_id"], :name => "abbp_index"

  create_table "aberrations_karyotypes", :id => false, :force => true do |t|
    t.integer "karyotype_id",  :null => false
    t.integer "aberration_id", :null => false
  end

  add_index "aberrations_karyotypes", ["karyotype_id", "aberration_id"], :name => "abk_index"

  create_table "breakpoints", :force => true do |t|
    t.string "breakpoint", :limit => 32, :null => false
  end

  add_index "breakpoints", ["id", "breakpoint"], :name => "bp_index"

  create_table "breakpoints_karyotypes", :id => false, :force => true do |t|
    t.integer "breakpoint_id", :null => false
    t.integer "karyotype_id",  :null => false
  end

  add_index "breakpoints_karyotypes", ["breakpoint_id", "karyotype_id"], :name => "bpk_index"

  create_table "cancer", :force => true do |t|
    t.text "name", :null => false
  end

  add_index "cancer", ["id", "name"], :name => "c_index", :length => {"id"=>nil, "name"=>12}

  create_table "cancer_lookup", :id => false, :force => true do |t|
    t.string "name",        :limit => 256, :null => false
    t.string "translation", :limit => 112, :null => false
  end

  create_table "cancers_karyotypes", :id => false, :force => true do |t|
    t.integer "karyotype_id", :null => false
    t.integer "cancer_id",    :null => false
  end

  add_index "cancers_karyotypes", ["karyotype_id", "cancer_id"], :name => "ck_index"

  create_table "cell_lines", :force => true do |t|
    t.string "name",        :limit => 32, :null => false
    t.text   "description"
  end

  add_index "cell_lines", ["id", "name"], :name => "cl_index"

  create_table "chromosome_bands", :force => true do |t|
    t.string  "chromosome", :limit => 12, :null => false
    t.string  "band",       :limit => 12, :null => false
    t.integer "start",                    :null => false
    t.integer "end",                      :null => false
  end

  create_table "karyotype_source", :force => true do |t|
    t.string   "source",          :limit => 112, :null => false
    t.string   "source_short",    :limit => 12,  :null => false
    t.text     "url"
    t.text     "description"
    t.datetime "date_accessed",                  :null => false
    t.integer  "karyotype_count",                :null => false
  end

  create_table "karyotypes", :force => true do |t|
    t.integer "karyotype_source_id",              :null => false
    t.string  "source_type",         :limit => 9, :null => false
    t.text    "karyotype",                        :null => false
    t.integer "cell_line_id"
    t.text    "description"
  end

  add_index "karyotypes", ["id", "cell_line_id"], :name => "kcellindex"
  add_index "karyotypes", ["id", "karyotype_source_id"], :name => "ksindex"

end
