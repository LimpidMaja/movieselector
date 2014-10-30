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

ActiveRecord::Schema.define(version: 20141030101132) do

  create_table "access_keys", force: true do |t|
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "access_token_expires"
    t.string   "gcm_reg_id"
  end

  create_table "actors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.string   "slug"
  end

  add_index "actors", ["slug"], name: "slug", unique: true, using: :btree

  create_table "authorizations", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token"
    t.string   "access_token_expires"
  end

  create_table "companies", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "companies", ["slug"], name: "slug", unique: true, using: :btree

  create_table "countries", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "countries", ["name"], name: "index_countries_on_name", unique: true, using: :btree
  add_index "countries", ["slug"], name: "slug", unique: true, using: :btree

  create_table "directors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.string   "slug"
  end

  add_index "directors", ["slug"], name: "slug", unique: true, using: :btree

  create_table "event_knockouts", force: true do |t|
    t.integer "movie_id_1"
    t.integer "movie_id_2"
    t.integer "movie_1_score"
    t.integer "movie_2_score"
    t.integer "event_id"
    t.integer "num_votes"
    t.integer "round",         default: 1
    t.boolean "finished",      default: false
  end

  create_table "event_movies", force: true do |t|
    t.integer "movie_id"
    t.integer "event_id"
    t.integer "num_votes"
    t.float   "score"
    t.boolean "out"
    t.boolean "winner"
  end

  create_table "event_user_votes", force: true do |t|
    t.integer  "movie_id"
    t.integer  "event_id"
    t.integer  "user_id"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_users", force: true do |t|
    t.integer "user_id"
    t.integer "event_id"
    t.integer "num_votes"
    t.integer "accept",    default: 0
  end

  create_table "events", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.date     "event_date"
    t.time     "event_time"
    t.string   "place"
    t.integer  "time_limit"
    t.integer  "minimum_voting_percent"
    t.integer  "user_id"
    t.boolean  "finished"
    t.boolean  "users_can_add_movies"
    t.integer  "num_add_movies_by_user"
    t.integer  "rating_system",          default: 0
    t.integer  "num_votes_per_user"
    t.integer  "voting_range",           default: 0
    t.boolean  "tie_knockout"
    t.integer  "knockout_rounds",        default: 5
    t.integer  "knockout_time_limit"
    t.boolean  "wait_time_limit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rating_phase",           default: 0
    t.integer  "knockout_phase",         default: 0
  end

  create_table "friends", force: true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.string   "facebook_id"
    t.boolean  "friend_confirm"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genres", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "genres", ["name"], name: "index_genres_on_name", unique: true, using: :btree
  add_index "genres", ["slug"], name: "slug", unique: true, using: :btree

  create_table "keywords", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "keywords", ["name"], name: "index_keywords_on_name", unique: true, using: :btree
  add_index "keywords", ["slug"], name: "slug", unique: true, using: :btree

  create_table "knockout_users", force: true do |t|
    t.integer "user_id"
    t.integer "event_knockout_id"
    t.integer "num_votes"
  end

  create_table "languages", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "languages", ["name"], name: "index_languages_on_name", unique: true, using: :btree
  add_index "languages", ["slug"], name: "slug", unique: true, using: :btree

  create_table "list_movies", force: true do |t|
    t.integer  "list_id"
    t.integer  "movie_id"
    t.integer  "list_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lists", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.string   "privacy",      default: "private"
    t.boolean  "allow_edit",   default: false
    t.string   "edit_privacy", default: "private"
    t.float    "rating",       default: 0.0
    t.integer  "votes_count",  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "watchlist",    default: false,     null: false
    t.string   "list_type"
  end

  create_table "movie_actors", force: true do |t|
    t.integer  "movie_id"
    t.integer  "actor_id"
    t.string   "role",       limit: 400
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "movie_actors", ["movie_id", "actor_id", "role"], name: "movie_id", unique: true, length: {"movie_id"=>nil, "actor_id"=>nil, "role"=>255}, using: :btree

  create_table "movie_writers", force: true do |t|
    t.integer  "movie_id"
    t.integer  "writer_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "movie_writers", ["movie_id", "writer_id", "role"], name: "movie_id", unique: true, using: :btree

  create_table "movies", force: true do |t|
    t.string   "imdb_id"
    t.string   "tmdb_id"
    t.string   "trakt_id"
    t.string   "title"
    t.integer  "year"
    t.string   "poster"
    t.float    "imdb_rating"
    t.integer  "imdb_num_votes", default: 0,    null: false
    t.text     "plot"
    t.integer  "runtime"
    t.text     "tagline"
    t.string   "trailer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fanart"
    t.string   "rated"
    t.string   "original_title"
    t.string   "budget"
    t.string   "revenue"
    t.string   "status"
    t.string   "awards"
    t.boolean  "missing_data",   default: true
    t.date     "release_date"
    t.string   "slug"
  end

  add_index "movies", ["imdb_id"], name: "imdb_id", unique: true, using: :btree
  add_index "movies", ["slug"], name: "slug", unique: true, using: :btree

  create_table "movies_companies", force: true do |t|
    t.integer "movie_id"
    t.integer "company_id"
  end

  add_index "movies_companies", ["movie_id", "company_id"], name: "movie_id", unique: true, using: :btree

  create_table "movies_countries", force: true do |t|
    t.integer "movie_id"
    t.integer "country_id"
  end

  add_index "movies_countries", ["movie_id", "country_id"], name: "movie_id", unique: true, using: :btree

  create_table "movies_directors", force: true do |t|
    t.integer "movie_id"
    t.integer "director_id"
  end

  add_index "movies_directors", ["movie_id", "director_id"], name: "movie_id", unique: true, using: :btree

  create_table "movies_genres", force: true do |t|
    t.integer "movie_id"
    t.integer "genre_id"
  end

  add_index "movies_genres", ["movie_id", "genre_id"], name: "movie_id", unique: true, using: :btree

  create_table "movies_keywords", force: true do |t|
    t.integer "movie_id"
    t.integer "keyword_id"
  end

  add_index "movies_keywords", ["movie_id", "keyword_id"], name: "movie_id", unique: true, using: :btree

  create_table "movies_languages", force: true do |t|
    t.integer "movie_id"
    t.integer "language_id"
  end

  add_index "movies_languages", ["movie_id", "language_id"], name: "movie_id", unique: true, using: :btree

  create_table "searchjoy_searches", force: true do |t|
    t.string   "search_type"
    t.string   "query"
    t.string   "normalized_query"
    t.integer  "results_count"
    t.datetime "created_at"
    t.integer  "convertable_id"
    t.string   "convertable_type"
    t.datetime "converted_at"
    t.integer  "user_id"
  end

  add_index "searchjoy_searches", ["convertable_id", "convertable_type"], name: "index_searchjoy_searches_on_convertable_id_and_convertable_type", using: :btree
  add_index "searchjoy_searches", ["created_at"], name: "index_searchjoy_searches_on_created_at", using: :btree
  add_index "searchjoy_searches", ["search_type", "created_at"], name: "index_searchjoy_searches_on_search_type_and_created_at", using: :btree
  add_index "searchjoy_searches", ["search_type", "normalized_query", "created_at"], name: "index_searchjoy_searches_on_search_type_and_normalized_query_an", using: :btree

  create_table "settings", force: true do |t|
    t.boolean  "private"
    t.string   "trakt_username"
    t.string   "trakt_password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "showtimes", force: true do |t|
    t.integer  "movie_id"
    t.string   "title"
    t.string   "original_title"
    t.string   "cinema"
    t.boolean  "is_3d"
    t.boolean  "is_synchronized"
    t.string   "city"
    t.string   "country"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "datetime"
  end

  create_table "user_movies", force: true do |t|
    t.integer  "user_id"
    t.integer  "movie_id"
    t.boolean  "watched",      default: false, null: false
    t.datetime "date_watched"
    t.boolean  "collection",   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "watchlist",    default: false
  end

  add_index "user_movies", ["user_id", "movie_id"], name: "user_id", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
  end

  add_index "users", ["email"], name: "sqlite_autoindex_users_1", unique: true, using: :btree
  add_index "users", ["username"], name: "sqlite_autoindex_users_2", unique: true, using: :btree

  create_table "writers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.string   "slug"
  end

  add_index "writers", ["slug"], name: "slug", unique: true, using: :btree

end
