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

ActiveRecord::Schema.define(:version => 20111009033713) do

  create_table "activated_topics", :force => true do |t|
    t.integer  "topic_id",                                       :null => false
    t.integer  "teacher_id",                                     :null => false
    t.integer  "credits",                                        :null => false
    t.integer  "duration",                                       :null => false
    t.integer  "semester_start",                                 :null => false
    t.integer  "prerequisite_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "delivery_type",   :limit => 4, :default => "TF", :null => false
    t.integer  "hours_in_mo",                  :default => 0,    :null => false
    t.integer  "hours_paid",                   :default => 0,    :null => false
    t.decimal  "teacher_gross",                :default => 0.0,  :null => false
    t.decimal  "teacher_net",                  :default => 0.0,  :null => false
    t.decimal  "school_gross",                 :default => 0.0,  :null => false
    t.text     "notes"
  end

  add_index "activated_topics", ["teacher_id"], :name => "index_activated_topics_on_teacher_id"
  add_index "activated_topics", ["topic_id"], :name => "index_activated_topics_on_topic_id"

  create_table "blacklisted_dates", :force => true do |t|
    t.datetime "blacklisted",                                                           :null => false
    t.string   "description", :limit => 4096, :default => "Il conservatorio è chiuso"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classrooms", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "place_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_starting_years", :force => true do |t|
    t.integer "course_id",                  :null => false
    t.string  "color",         :limit => 7, :null => false
    t.integer "starting_year", :limit => 4
  end

  add_index "course_starting_years", ["course_id"], :name => "index_course_starting_years_on_course_id"

  create_table "course_topic_relations", :force => true do |t|
    t.integer "activated_topic_id",                                     :null => false
    t.integer "course_starting_year_id",                                :null => false
    t.string  "teaching_typology",       :limit => 2, :default => "C",  :null => false
    t.boolean "mandatory_flag",                       :default => true, :null => false
    t.integer "course_year",                                            :null => false
  end

  add_index "course_topic_relations", ["activated_topic_id"], :name => "index_course_topic_relations_on_activated_topic_id"
  add_index "course_topic_relations", ["course_starting_year_id"], :name => "index_course_topic_relations_on_course_starting_year_id"

  create_table "courses", :force => true do |t|
    t.string   "name",                    :null => false
    t.string   "acronym",    :limit => 5, :null => false
    t.integer  "duration",                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lesson_conflicts", :force => true do |t|
    t.integer "left_lesson_id"
    t.integer "right_lesson_id"
  end

  add_index "lesson_conflicts", ["left_lesson_id"], :name => "index_lesson_conflicts_on_left_lesson_id"
  add_index "lesson_conflicts", ["right_lesson_id"], :name => "index_lesson_conflicts_on_right_lesson_id"

  create_table "lessons", :force => true do |t|
    t.datetime "start_date",         :null => false
    t.datetime "end_date",           :null => false
    t.text     "description"
    t.integer  "activated_topic_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "place_id"
  end

  add_index "lessons", ["activated_topic_id"], :name => "index_lessons_on_activated_topic_id"
  add_index "lessons", ["place_id"], :name => "index_lessons_on_place_id"

  create_table "places", :force => true do |t|
    t.string   "name",                                                                                                                                                                                                                                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "street",     :default => "",                                                                                                                                                                                                               :null => false
    t.string   "number",     :default => "",                                                                                                                                                                                                               :null => false
    t.string   "city",       :default => "",                                                                                                                                                                                                               :null => false
    t.string   "url",        :default => "http://maps.google.it/maps?f=q&source=s_q&hl=it&geocode=&q=padova&sll=45.419721,11.888237&sspn=0.027653,0.077162&ie=UTF8&hq=&hnear=Padova,+Veneto&ll=45.409568,11.876585&spn=0.006914,0.01929&t=h&z=16&iwloc=A", :null => false
  end

  create_table "topics", :force => true do |t|
    t.string   "name",                     :null => false
    t.string   "acronym",     :limit => 7, :null => false
    t.string   "color",       :limit => 7, :null => false
    t.integer  "level"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                          :null => false
    t.string   "first_name",                                     :null => false
    t.string   "last_name",                                      :null => false
    t.string   "email",                                          :null => false
    t.string   "url"
    t.string   "type",                                           :null => false
    t.string   "password",                                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "teacher_typology", :limit => 1, :default => "I", :null => false
  end

end
