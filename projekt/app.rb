require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

#Loads documents with functions
require_relative './db_function.rb'
require_relative './functions.rb'

include DB_Functions
include Server_Functions
#Enables client sessions for instance data storage. 
enable :sessions

#Approved by Emil
class Array
    def difference(other)
        h = other.each_with_object(Hash.new(0)) { |e,h| h[e] += 1 }
        reject { |e| h[e] > 0 && h[e] -= 1 }
    end
end

#Routes to Main 
get('/') do
    slim(:home)
end

#Checks if the user is logged in and it's authorization
before do
    if session[:user_liked] == nil
        session[:user_liked] = {}
    end
    session[:error_msg] = ""
    session[:user_id] = 1
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

#Routes to Sign_in
get('/sign_in') do
    slim(:'user/sign_in')
end

#Post command that signs a user in to the website
post('/sign_in_user') do
    session[:user_liked] = {}
    result = sign_in(params[:username], params[:password])
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
        insert('users', ['username','password_digest','role','email'], [params[:username], password_digest,'user',params[:email]])
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

#Look at your own profile
get('/profile') do
    result = select('users', 'id', session[:user_id])
    slim(:'user/profile',locals:{profile:result[0],is_user:true})
end
 
#Test routes for different functions 
get('/test') do 
    genres = select_all('genre', 'id')
    p genres
    p genres.length
    slim(:test)
end

get('/post/create') do
    genres = select('genre')
    slim(:'/posts/create',locals:{genres:genres})
end

post('/create_post_db') do
    #calls image_to_dir function from function.rb
    while true
        image_id = image_to_dir(params[:image])
        if select('posts', 'content_image', image_id) == []
            break
        end
    end
    insert('posts', ['content_image', 'content_title', 'content_text', 'date', 'user_id'], [image_id, params[:title], params[:content_text], Time.now.to_i, session[:user_id]])
    post_id = select('posts', 'content_image', image_id, 'id')[0]
    genres = select_all('genre', 'id')
    p genres
    p params
    ids = [] 
    genres.each do |genre|
        if params[genre['id'].to_s] != nil
            ids << genre['id']
        end
    end
    ids.each do |id| 
        genre_post_link('insert', post_id['id'], id)
    end
    redirect('/')
end

get('/post/:post_id') do
    num_str = "1234567890"
    params[:post_id].chars.difference(num_str.chars).empty? ? search = 'id' : search = 'content_image'
    result = select('posts', search ,params[:post_id])
    if result == []
        session[:error_msg] = "No post with that Id was found"
        slim(:main)
    else
        user = select('users', 'id', result[0]['user_id'])
        comments = select('comments', 'post_id', params[:post_id])
        age = time_since_created(result[0]['date'])
        for comment in comments do 
            comment['time_created'] = time_since_created(comment['date'])
            user_result = select('users', 'id', comment['user_id'], 'username, id')[0]
            comment['user_commented'] = user_result['username']
        end
        userliked = session[:user_liked][params[:post_id]]
        genres = get_genres_for_post(params[:post_id].to_i)
        slim(:'/posts/view', locals:{info:result[0],user:user[0],age:age,comments:comments,userliked:userliked,genres:genres})
    end     
end

post('/create_comment') do
    insert('comments', ['post_id', 'user_id', 'content_text', 'date'], [params[:post_id], session[:user_id], params[:content], Time.now.to_i])
    path = '/post/' + params[:post_id].to_s
    redirect(path)
end

post('/update_comment') do
    if session[:user_id] == select('comments', 'id', params[:comment_id], 'user_id')[0]['user_id']
        update('comments', params[:comment_id], 'content_text', params[:comment])
    end
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

post('/delete_comment') do 
    comment_result = select('comments', 'id', params[:comment_id], 'user_id')[0]
    user_role = select('users', 'id', session[:user_id], 'role')[0]
    if session[:user_id] == comment_result['user_id'] || user_role['role'] = 'admin'
        delete('comments', params[:comment_id])
    end
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

post('/like_post') do
    session[:user_liked][params[:post_id]] = true
    increment('posts', params[:post_id], 'points', 1)
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

post('/unlike_post') do
    session[:user_liked][params[:post_id]] = false
    increment('posts', params[:post_id], 'points', -1)
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end