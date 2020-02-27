require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

#Connects to the disered database
def connect_to_db(path) #path is a string
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db   
end

#Takes a set of inputs and constructs, executes, selects and returns the correct values
def select(table, search, search_values, elements='*', database_path='database/db.db')
    db = connect_to_db(database_path)
    #Construction of SQL string
    if search_values.is_a?(Integer)
        search_values = search_values.to_s
    end
    sql_str = 'SELECT ' + elements + ' FROM ' + table + ' WHERE ' + search + " = '" + search_values + "'"
    return db.execute(sql_str)
end


# Takes an array as input and converts it into a string of values or elements for SQL
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