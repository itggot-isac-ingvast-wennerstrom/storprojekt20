require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

# All the functions that interact with the database

module DB_Functions
    
    require_relative './functions.rb'
    include Server_Functions
    #Connects to the disered database
    #
    # @param [String] path The path for the database
    #
    # @return [Database] The database that is referenced
    def connect_to_db(path) #path is a string
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db   
    end

    #Constructs and executes a SELECT command in SQL
    #
    # @param [String] table The table that the command selects from
    # @param [String] search The parameters that are used to select data
    # @param [String] search_values The requested values for the search parameters
    # @param [String] elements The elements that gets selected.
    # @param [String] database_path The path to the database that the command selects from.
    #
    # @return [Array] The result from the select command. Contains the data as hashes
    def select(table, search, search_values, elements='*', database_path='database/db.db')
        #Connects to Database
        db = connect_to_db(database_path)
        #Checks if search_values is the same length as search
        if search.empty? 
            !(search_values.empty?) ? session[:error_msg] = 'SQL Error' : false
            sql_str = 'SELECT * FROM ' + table
            return db.execute(sql_str)
        else
           # search_values.empty? ? session[:error_msg] = 'SQL Error' : false
        end
        if search.is_a?(Array) != search_values.is_a?(Array)
            return {'msg' => "SQL Input Error"}
        end
        if search.is_a?(Array) && search_values.length != search.length 
            return {'msg' => "SQL Input Error"}
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
            return {'msg' => "SQL Error"}
        end
        return result
    end

    #Constructs and executes an INSERT command in SQL
    #
    # @param [String] table The table that the command inserts into
    # @param [Array] elements The elements that gets inserted
    # @param [Array] values The corresponding values that gets inserted for the elements
    # @param [String] database_path The path for the database that the command execute on
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
            return {'msg' => "SQL Error"}
        end
    end

    # Signs a user into the website and updates the session
    #
    # @param [String] username The username used for the login
    # @param [String] password The password used for the login
    def sign_in(username, password)
        result = select('users', 'username',params[:username])
        #Checks if there's a user with that username
        p result
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

    # Updates a entry into the database
    #
    # @param [String] table The table that the command updates from
    # @param [String] id The id for the entry that gets updated
    # @param [Array] elements The elements that gets updated
    # @param [Array] values The values for the corresponding elements
    # @param [String] database_path The path for the database that the command executes on
    def update(table, id, elements, values, database_path='database/db.db')
        #Connects to Database
        db = connect_to_db(database_path)
        #Checks if both elements and values are arrays
        is_arr = values.is_a?(Array)
        num = 1
        is_arr == elements.is_a?(Array) ? num = elements.length : (return nil)
        #Creates a string of the attributes that will change and their values to '?'
        #aswell as creating an array of things to update
        param_str = ""
        update = []
        if is_arr
            for i in 0...num do
                param_str += elements[i].to_s + ' = ?,' 
            end
            param_str[-1] = ""
            update = values + [id]
        else
            param_str = elements.to_s + ' = ?'
            update = [values, id]
        end

        #Cases for different table types
        case table
        when 'users'
            #Creates SQL String to execute
            sql_str = 'UPDATE users SET ' + param_str + ' WHERE id = ?'
            #Executes SQL String with the respective values
            db.execute(sql_str, update)        
        when 'posts'
            #Creates SQL String to execute
            sql_str = 'UPDATE posts SET ' + param_str + ' WHERE id = ?'
            #Executes SQL String with the respective values
            db.execute(sql_str, update)
        when 'comments'
            #Creates SQL String to execute
            sql_str = 'UPDATE comments SET ' + param_str + ' WHERE id = ?'
            #Executes SQL String with the respective values
            db.execute(sql_str, update)        
        when 'genre'
            #Creates SQL String to execute
            sql_str = 'UPDATE genre SET ' + param_str + ' WHERE id = ?'
            #Executes SQL String with the respective values
            db.execute(sql_str, update)           
        else 
            return {'msg' => "SQL Error"}
        end
    end

    # Deletes an entry in a database
    #
    # @param [String] table The table that the command deletes from
    # @param [String] id The id for the entry that gets deleted
    # @param [String] database_path The path for the database that the command gets executed on
    def delete(table, id, database_path='database/db.db')
        #Connects to Database
        db = connect_to_db(database_path)
        #Cases for different table types
        case table
        when 'users'
            #Executes SQL with the respective values
            db.execute('DELETE FROM users WHERE id = ?', id)        
        when 'posts'
            #Executes SQL with the respective values
            db.execute('DELETE FROM posts WHERE id = ?', id)         
        when 'comments'
            #Executes SQL with the respective values
            db.execute('DELETE FROM comments WHERE id = ?', id)       
        when 'genre'
            #Executes SQL with the respective values
            db.execute('DELETE FROM genre WHERE id = ?', id)            
        else 
            return {'msg' => "SQL Error"}
        end
    end

    # Increments a point value in an entry
    #
    # @param [String] table The table that the command updates on
    # @param [String] id The id for the entry that the command updates
    # @param [String] value The field that gets updated
    # @param [Integer] inc The value that the field gets incremented with
    # @param [String] database_path The path for the database that the command executes on
    def increment(table, id, value, inc, database_path='database/db.db')
        #Connects to Database
        db = connect_to_db(database_path)
        #Creates incrementing SQL string
        sql_str = value + ' = '+ value + ' + ' + inc.to_s 
        #Cases for different table types
        p sql_str
        case table
        when 'users'
            #Executes SQL with the respective values
            db.execute('UPDATE users SET ' + sql_str + ' WHERE id = ?', id)        
        when 'posts'
            #Executes SQL with the respective values
            db.execute('UPDATE posts SET ' + sql_str + ' WHERE id = ?', id)        
        when 'comments'
            #Executes SQL with the respective values
            db.execute('UPDATE comments SET ' + sql_str + ' WHERE id = ?', id)        
        when 'genre'
            #Executes SQL with the respective values
            db.execute('UPDATE genre SET ' + sql_str + ' WHERE id = ?', id)        
        else 
            return {'msg' => "SQL Error"}
        end
    end

    # SQL commands for the Genre and Post link table
    #
    # @param [String] table_do The selected option for the different types of command that can get chosen
    # @option table_do [String] insert Insert command for the genre_post_link table
    # @option table_do [String] delete Delete command for the genre_post_link table
    # @option table_do [String] select_post Select command for the genre_post_link table using the post_id
    # @option table_do [String] select_genre Select command for the genre_post_link table using the genre_id
    # @param [String] post_id The value for the post_id for the select_post command. 
    # @param [String] genre_id The value for the genre_id for the select_genre command. 
    #
    # @return [Array] 
    #   * :nil If the command insert or delete is used the Array is empty
    #   * :value_array If the command select_post or select_genre is used returns the values of that entry
    def genre_post_link(table_do, post_id=nil, genre_id=nil)
        db = connect_to_db('database/db.db')
        if post_id == nil && genre_id == nil
            return return {'msg' => "SQL Input Error"}
        end
        case table_do
        when 'insert'
            db.execute('INSERT INTO genre_post_link VALUES (?,?)', [post_id, genre_id])
        when 'delete'
            db.execute('DELETE FROM genre_post_link WHERE (post_id, genre_id) = (?,?)', [post_id, genre_id])
        when 'select_post'
            return db.execute('SELECT * FROM genre_post_link WHERE post_id = ?', post_id)
        when 'select_genre'
            return db.execute('SELECT * FROM genre_post_link WHERE genre_id = ?', genre_id)
        end
    end
    
    # Selects all entries and their field values in a table
    #
    # @param [String] table The table that the command deletes from
    # @param [String] elements The elements that gets selected from every entry.
    # @param [String] database_path The path for the database that the table exists in
    #
    # @return [Array] 
    #   * :entry [Hash] A Hash of all the fields with their values
    def select_all(table, elements='*', database_path='database/db.db')
        db = connect_to_db(database_path)
        return db.execute('SELECT ' + elements + ' FROM ' + table)
    end

    # Gets the genres for a post using a nested SQL command
    #
    # @param [String] post_id The post_id used for the selection
    # @param [String] database_path The path for the database that the command executes on
    #
    # @return [Array]
    #   * :entry [Array] an array of hashes for that entry in the genre table 
    def get_genres_for_post(post_id, database_path='database/db.db')
        db = connect_to_db(database_path)
        return db.execute('SELECT * FROM genre WHERE id IN (SELECT genre_id FROM genre_post_link WHERE post_id = ?)', post_id)
    end
end

