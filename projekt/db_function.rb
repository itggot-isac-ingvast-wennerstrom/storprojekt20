require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

load 'functions.rb'

#Connects to the disered database
def connect_to_db(path) #path is a string
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db   
end

#Constructs and executes a SELECT command in SQL
def select(table, search, search_values, elements='*', database_path='database/db.db')
    #Connects to Database
    db = connect_to_db(database_path)
    #Checks if search_values is the same length as search
    if search.is_a?(Array) != search_values.is_a?(Array)
        session[:error_msg] = "SQL Error"
        return []
    end
    if search.is_a?(Array) && search_values.length != search.length 
        session[:error_msg] = "SQL Error"
        return []
    end
    #Creates array of search parameters and respective values
    if search.is_a?(Array)
        search_arr = search + search_values
        #Creates a string of ? to match the length of the search_values
        question_str = ''
        num = search_values.length
        num.times {question_str += '?,'}
        question_str[-1] = ''
        search_str = arr_to_str(search)
    else
        search_arr = search_values
        question_str = '?'
        search_str = search
    end
    #Cases for different table types
    case table
    when 'users'
        #Creates SQL string to execute
        sql_str = 'SELECT '+ elements +' FROM users WHERE ' + search_str + ' = ' + question_str
        #Execute SQL string with respective values
        result = db.execute(sql_str, search_arr)
    when 'comments'
        #Creates SQL string to execute
        sql_str = 'SELECT '+ elements +' FROM comments WHERE ' + search_str + ' = ' + question_str
        #Execute SQL string with respective values
        result = db.execute(sql_str, search_arr)
    when 'posts'
        #Creates SQL string to execute
        sql_str = 'SELECT '+ elements +' FROM posts WHERE ' + search_str + ' = ' + question_str
        #Execute SQL string with respective values
        result = db.execute(sql_str, search_arr)
    when 'genre'
        #Creates SQL string to execute
        sql_str = 'SELECT '+ elements +' FROM genre WHERE ' + search_str + ' = ' + question_str
        #Execute SQL string with respective values
        result = db.execute(sql_str, search_arr)
    else
        session[:error_msg] = 'SQL Error'
    end
    return result
end

#Constructs and executes an INSERT command in SQL
def insert(table, elements, values, database_path='database/db.db')
    #Connects to Database
    db = connect_to_db(database_path)
    #Checks if values is the same length as elements
    if values.length != elements.length
        session[:error_msg] = "SQL Error"
        return nil
    end
    #Creates a string of ? to match the length of the values
    question_str = ''
    num = values.length
    num.times {question_str += '?,'}
    question_str[-1] = ')'
    #Creates String of elements
    elements_str = arr_to_str(elements)
    #Cases for different table types
    case table
    when 'users'
        #Creates SQL String to execute
        sql_str = 'INSERT INTO users ' + elements_str + ' VALUES (' + question_str
        #Executes SQL String with the respective values
        db.execute(sql_str, values)        
    when 'posts'
        #Creates SQL String to execute
        sql_str = 'INSERT INTO posts ' + elements_str + ' VALUES (' + question_str
        #Executes SQL String with the respective values
        db.execute(sql_str, values)
    when 'comments'
        #Creates SQL String to execute
        sql_str = 'INSERT INTO comments ' + elements_str + ' VALUES (' + question_str
        #Executes SQL String with the respective values
        db.execute(sql_str, values)        
    when 'genre'
        #Creates SQL String to execute
        sql_str = 'INSERT INTO genre ' + elements_str + ' VALUES (' + question_str
        #Executes SQL String with the respective values
        db.execute(sql_str, values)           
    else 
        session[:error_msg] = "SQL Error"
    end
end

def sign_in(username, password)
    result = select('users', 'username',params[:username])
    #Checks if there's a user with that username
    if result == []
        return 'wrong username'
    end
    #Encrypts the password and checks if the passwords match
    if BCrypt::Password.new(result[0]['password_digest']) == password
        return result[0]['id']
    else
        return "wrong password"
    end
end