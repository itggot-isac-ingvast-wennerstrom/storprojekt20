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
    db = connect_to_db(database_path)
    sql_str = ''    
    #If an argument is empty it returns an error message.
    if table == "" || elements == "" || values == ""
        session[:error_msg] = "One argument is empty"
        return nil
    end
    #Checks if it's an array of elements or values
    if elements.is_a?(Array)
        if values.is_a?(Array)
            #Checks that the number of elements and values matches
            if values.length == elements.length
                #Converts the arrays into SQL friendly strings
                values = arr_to_str(values, '"')
                elements = arr_to_str(elements)
                #Constructs SQL string
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
        #If it's not an array continue as normal and construct SQL string
        sql_str = 'INSERT INTO '+table+' '+elements+' VALUES '+values
    end
    #Execute SQL string
    db.execute(sql_str)
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