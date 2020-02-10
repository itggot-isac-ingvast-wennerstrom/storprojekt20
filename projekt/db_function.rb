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

def arr_to_str(input, mod='')
    str = "("
    input.each do |item|
        if item.is_a?(String)
            str+= mod + item + mod + ','
        else
            str+= item.to_s + ','
        end
    end
    str[-1] = ')'
    return str
end

def insert(table, elements, values, database_path='database/db.db')
    db = connect_to_db(database_path)
    sql_str = ''    
    if table == "" || elements == "" || values == ""
        session[:error_msg] = "One argument is empty"
        return nil
    end
    if elements.is_a?(Array)
        if values.is_a?(Array)
            if values.length == elements.length
                values = arr_to_str(values, '"')
                elements = arr_to_str(elements)
                sql_str = 'INSERT INTO '+table+' '+elements+' VALUES '+values
            else
                session[:error_msg] = 'Wrong number of elements or values'
                return nil
            end
        else 
            session[:error_msg] = 'Wrong number of elements or values'
            return nil
        end
    else
        sql_str = 'INSERT INTO '+table+' '+elements+' VALUES '+values
    end
    p sql_str
    db.execute(sql_str)
end