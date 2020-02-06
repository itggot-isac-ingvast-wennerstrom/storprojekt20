require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

def connect_to_db(path) #path is a string
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db   
end

def select(table, search, search_values, elements='*', database_path='database/db.db')
    db = connect_to_db(database_path)
    sql_str = 'SELECT ' + elements + ' FROM ' + table + ' WHERE ' + search + " = '" + search_values + "'"
    p sql_str
    db.execute(sql_str)
end