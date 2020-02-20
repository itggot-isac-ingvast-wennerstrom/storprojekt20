require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

#Loads documents with functions
load 'functions.rb'
load 'db_function.rb'

enable :sessions

#Routes to Main 
get('/') do
    slim(:main)
end

#Checks if the user is logged in and it's authorization
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

after do
    session[:error_msg] = ""
end

#Routes to Sign_in
get('/sign_in') do
    slim(:'user/sign_in')
end

#Post command that signs a user in to the website
post('/sign_in_user') do
    session[:error_msg] = ""
    result = sign_in(params[:username], params[:password])
    #
    case result
    when 'wrong username'
        session[:error_msg] = "No user with that username"
        break
    when 'wrong password'
        session[:error_msg] = "Password is wrong"
        break
    else
        session[:user_id] = result
        redirect('/')
    end
end

#Routes to Sign_up
get('/sign_up') do
    slim(:'user/create_user')
end

#Post that creates a user
post('/create_user') do
    session[:error_msg] = ""
    if params[:password] != params[:password_conf] #Checking if passwords match
        session[:error_msg] = "Passwords do not match"
        redirect('/sign_up')
    end
    valid_email = validate_email(params[:email]) #Validate email from function.rb
    if !valid_email 
        session[:error_msg] = "Invalid email"
        redirect('/sign_up')
    end
    #Encrypts password
    password_digest = BCrypt::Password.create(params[:password])
    #Inserts values into the database
    if select('users', 'username',params[:username]) == []
        insert('users', ['username','password_digest','role','points','email'], [params[:username],     password_digest,'user',0,params[:email]])
        #Tells the website the user is logged in
        session[:user_id] = select('users','username',params[:username],'id')
        redirect('/new_user_registred')
    else
        session[:error_msg] = "Account already exists with that username"
        redirect('/sign_up')
    end
end

#Routes to new_user_registred
get('/new_user_registred') do
    slim(:'user/new_user_reg')
end

#Restful route to the selected users profile
get('/profile/:username') do
    result = select('users', 'username', params[:username])
    if session[:user_id] == result[0]['id']
        is_user = true
    else
        is_user = false
    end
    slim(:'user/profile',locals:{profile:result[0],is_user:is_user})
end

get('/profile') do
    
end
 
#Test routes for different functions 
get('/test') do 
    result = select('users', 'username', 'hej')
    slim(:test,locals:{result:result})
end
