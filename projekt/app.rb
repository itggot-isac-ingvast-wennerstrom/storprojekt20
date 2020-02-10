require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

load 'functions.rb'
load 'db_function.rb'

enable :sessions

get('/') do
    slim(:main)
end

before do
    if session[:user_id] == nil
        case request.path_info
        when '/'
            break     
        when '/sign_in'
            break
        when '/sign_in_user'
            break
        when '/create_user'
            break
        when '/sign_up'
            break
        when '/test'
            break
        else
            session[:error_msg] = "You must be logged in to acess this"
            redirect('/sign_in')
        end    
    end
end 

get('/sign_in') do
    slim(:'user/sign_in')
end

post('/sign_in_user') do
    session[:error_msg] = ""
    db = connect_to_db('database/db.db')
    result = select('users', 'username',params[:username])
    if result == []
        session[:error_msg] = "No user with that username"
        redirect('/sign_in')
    end
    if BCrypt::Password.new(result[0]['password_digest']) == params[:password]
        session[:user_id] = result[0]['id']
        redirect('/profile')
    else
        session[:error_msg] = "Password is wrong"
        redirect('/sign_in')
    end
end

get('/sign_up') do
    slim(:'user/create_user')
end

post('/create_user') do
    session[:error_msg] = ""
    username = params[:username]
    password = params[:password]
    password_conf = params[:password_conf]
    email = params[:email]
    if password != password_conf #Checking if passwords match
        session[:error_msg] = "Passwords do not match"
        redirect('/sign_up')
    end
    valid_email = validate_email(email) #Validate email from function.rb
    if !valid_email 
        session[:error_msg] = "Invalid email"
        redirect('/sign_up')
    end
    password_digest = BCrypt::Password.create(password)
    insert('users', ['username','password_digest','role','points','email'], [username,password_digest,'user',0,email])
    session[:user_id] = select('users','username',username,'id')
    redirect('/new_user_registred')
end

get('/new_user_registred') do
    slim(:'user/new_user_reg')
end

get('/profile') do
    db = connect_to_db('database/db.db')
end

get('/profile/:username') do
    db = connect_to_db('database/db.db')    
    result = db.execute('SELECT * FROM users WHERE username = ?', params[:username])
    if session[:user_id] == result[0]['id']
        is_user = true
    else
        is_user = false
    end
    slim(:'user/profile',locals:{profile:result[0],is_user:is_user})
end

get('/test') do 
    result = select('users', 'username', 'hej')
    slim(:test,locals:{result:result})
end