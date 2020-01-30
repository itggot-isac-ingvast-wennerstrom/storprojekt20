require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

def connect_to_db(path) #path is a string
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db   
end

