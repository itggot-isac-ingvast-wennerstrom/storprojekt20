require 'sqlite3'
require 'slim'
require 'sinatra'
require 'bcrypt'

# require_relative './functions.rb'
# include Server_Functions

module DB_Functions
    
    require_relative './functions.rb'
    include Server_Functions
    #Connects to the disered database
    def connect_to_db(path) #path is a string
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db   
    end

    #Constructs and executes a SELECT command in SQL
    def select(table, search="", search_values="", elements='*', database_path='database/db.db')
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

    def update(table, id, elements, values, database_path='database/db.db')
        #Connects to Database
        db = connect_to_db(database_path)
        #Checks if values is the same length as elements
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
            param_str[-1] = " "
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
            p sql_str
            p update
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
            session[:error_msg] = "SQL Error"
        end
    end

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
            session[:error_msg] = "SQL Error"
        end
    end

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
            session[:error_msg] = "SQL Error"
        end
    end

    def genre_post_link(table_do, post_id, genre_id)
        db = connect_to_db('database/db.db')

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

    def select_all(table, elements='*', database_path='database/db.db')
        db = connect_to_db(database_path)
        return db.execute('SELECT ' + elements + ' FROM ' + table)
    end

    def get_genres_for_post(post_id, database_path='database/db.db')
        db = connect_to_db(database_path)
        return db.execute('SELECT * FROM genre WHERE id IN (SELECT genre_id FROM genre_post_link WHERE post_id = ?)', post_id)
    end
end

