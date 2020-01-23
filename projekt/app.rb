require 'slim'
require 'sinatra'
require 'sqlite3'
load 'functions.rb'

enable :sessions

get('/') do
    slim(:main)
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
    valid_email = validate_email(email) #Validate email funkar inte
    if !valid_email 
        session[:error_msg] = "Invalid email"
        redirect('/sign_up')
    end
end