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

# Display Landing Page
#
get('/') do
    slim(:main)
end

#Checks if the user is logged in and it's authorization
#
before do
    if session[:user_liked] == nil
        session[:user_liked] = {}
    end
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
        else
            session[:error_msg] = "You must be logged in to acess this"
            redirect('/sign_in')
        end    
    end
end 


# Displays a sign in form
#
get('/sign_in') do
    slim(:'user/sign_in')
end

# Attempts Login and updates the session
#
# @param [String] username The username
# @param [String] password The password
#
# @see DB_Functions#sign_in
post('/sign_in_user') do
    session[:user_liked] = {}
    result = sign_in(params[:username], params[:password])
    if result['msg'] != nil    
        case result
        when 'wrong username'
            session[:error_msg] = "No user with that username"
        when 'wrong password'
            session[:error_msg] = "Password is wrong"
        else
            p result
            session[:user_id] = result
        end
    else 
        session[:error_msg] = result['info']
    end
    redirect('/')
end

# Displays a Sign up form 
# 
get('/sign_up') do
    slim(:'user/create_user')
end

# Attempts to create a new user and updates session
#
# @param [String] username The username
# @param [String] password The password 
# @param [String] password_conf The password confirmation
# @param [String] email The selected email adress for the user
# 
# @see DB_Functions#select
# @see DB_Functions#insert
# @see Server_Functions#validate_email
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
    result = select('users', 'username',params[:username])
    if result == []
        insert('users', ['username','password_digest','role','email'], [params[:username], password_digest,'user',params[:email]])
        #Tells the website the user is logged in
        session[:user_id] = select('users','username',params[:username],'id')
        redirect('/new_user_registred')
    else
        result['msg'] != nil ? session[:error_msg] = result['msg'] : session[:error_msg] = "Account already exists with that username"
        redirect('/sign_up')
    end
end

# Displays a welcome page
#
get('/new_user_registred') do
    slim(:'user/new_user_reg')
end

# Displays a single profile
#
# @param [String] username The username of the profile that should be viewed
#
# @see DB_Functions#select
get('/profile/:username') do
    result = select('users', 'username', params[:username])
    if session[:user_id] == result[0]['id']
        is_user = true
    else
        is_user = false
    end
    if result['msg'] != nil
        session[:error_msg] = result['msg']
    end
    slim(:'user/profile',locals:{profile:result[0],is_user:is_user})
end

# Displays the logged in users profile
#
# @see DB_Functions#select
get('/profile') do
    result = select('users', 'id', session[:user_id])
    result['msg'] == nil ? true : session[:error_msg] = result['msg']
    slim(:'user/profile',locals:{profile:result[0],is_user:true})
end

# Displays a form for creating a post
#
# @see DB_Functions#select_all
get('/post/create') do
    result = select_all('genre')
    result['msg'] == nil ? true : session[:error_msg] = result['msg']
    slim(:'/posts/create',locals:{genres:result})
end

# Attempts to create a post
#
# @param [String] title The title for the post
# @param [String] content_text The text that is displayed below the title
# @param [File] image The image that is uploaded to the website
#
# @see DB_Functions#select
# @see DB_Functions#insert
# @see DB_Functions#select_all
# @see DB_Functions#genre_post_link
# @see Server_Functions#image_to_dir 
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

# Displays a post
#
# @param [String] post_id The id for the selected post
#
# @see DB_Functions#select
# @see DB_Functions#select_all
# @see DB_Functions#get_genres_for_post
# @see Server_Functions#time_since_created
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
        edit_genres = select_all('genre')
        slim(:'/posts/view', locals:{info:result[0],user:user[0],age:age,comments:comments,userliked:userliked,genres:genres,edit_genres:edit_genres})
    end
end

# Creates a comment on a post
#
# @param [String] post_id The post id that the comment is created for
# @param [String] user_id The id of the user that creates the comment
# @param [String] content The text that the comment contains
#
# @see DB_Functions#insert
post('/create_comment') do
    insert('comments', ['post_id', 'user_id', 'content_text', 'date'], [params[:post_id], session[:user_id], params[:content], Time.now.to_i])
    path = '/post/' + params[:post_id].to_s
    redirect(path)
end

# Attempts to update a comment
#
# @param [String] comment_id The id of the comment that should update
# @param [String] comment The new text for the comment
# @param [String] post_id The post_id that the comment is attached to
#
# @see DB_Functions#update
# @see DB_Functions#select
post('/update_comment') do
    if session[:user_id] == select('comments', 'id', params[:comment_id], 'user_id')[0]['user_id']
        update('comments', params[:comment_id], 'content_text', params[:comment])
    end
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

# Attempts to delete a comment
#
# @param [String] comment_id The id of the comment that should gets deleted
# @param [String] post_id The post_id that the comment was attached to
#
# @see DB_Functions#select
# @see DB_Functions#delete
post('/delete_comment') do 
    comment_result = select('comments', 'id', params[:comment_id], 'user_id')[0]
    user_role = select('users', 'id', session[:user_id], 'role')[0]
    if session[:user_id] == comment_result['user_id'] || user_role['role'] = 'admin'
        delete('comments', params[:comment_id])
    end
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

# Likes a post and updates session
#
# @param [String] post_id The id of the post that gets liked
# 
# @see DB_Functions#increment
post('/like_post') do
    session[:user_liked][params[:post_id]] = true
    increment('posts', params[:post_id], 'points', 1)
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

# Unlikes a post and updates session
#
# @param [String] post_id The id of the post that gets unliked
#
# @see DB_Functions#increment
post('/unlike_post') do
    session[:user_liked][params[:post_id]] = false
    increment('posts', params[:post_id], 'points', -1)
    path = '/post/' + params[:post_id].to_s
    redirect(path) 
end

# Updates a post
#
# @param [String] post_id The id of the post that gets updated
# @param [String] title The new title of the post
# @param [String] content_text The new text for the post
# 
# @see DB_Functions#update
# @see DB_Functions#select
# @see DB_Functions#genre_post_link
# @see DB_Functions#select_all
post('/update_post') do
    post_result = select('posts', 'id', params[:post_id], 'user_id')[0]
    user_role = select('users', 'id', session[:user_id], 'role')[0]
    if session[:user_id] == post_result['user_id'] || user_role['role'] = 'admin'
        element_arr =  ['content_title', 'content_text']
        val_arr = [params[:title], params[:content_text]]
        update('posts', params['post_id'], element_arr, val_arr)
        genres_existing = genre_post_link('select_post', params[:post_id])
        i = 0
        while i < genres_existing.length
            genres_existing[i] = genres_existing[i]['genre_id']
            i += 1
        end
        genres = select_all('genre', 'id')
        i = 0 
        while i < genres.length
            genres[i] = genres[i]['id']
            i += 1
        end
        ids = []
        genres.each do |genre_id|
            if params[genre_id.to_s] != nil
                ids << genre_id
            end
        end
        remove = genres_existing - ids
        remove.each do |rem|
            genre_post_link('delete', params[:post_id], rem)
        end
        add = ids - genres_existing
        add.each do |ads|
            genre_post_link('insert', params[:post_id], ads)
        end
    end
    path = '/post/' + params[:post_id]
    redirect(path)
end

# Attempts to delete a post
#
# @param [String] post_id The id of the post that gets deleted
#
# @see DB_Functions#delete
# @see DB_Functions#select
post('/delete_post') do 
    post_result = select('posts', 'id', params[:post_id], 'user_id')[0]
    user_role = select('users', 'id', session[:user_id], 'role')[0]
    if session[:user_id] == post_result['user_id'] || user_role['role'] = 'admin'
        delete('posts', params[:post_id])
    end
    redirect('/')
end

# Searches for users using their username
#
# @param [String] username The username being used for the search
#
# @see DB_Functions#select
post('/search_user') do 
    result = select('users', 'username', params[:username], 'id')
    if result == []
        session[:error_msg] = "No user exists with that username"
        redirect('/')
    else
        path = '/profile/' + params[:username]
        redirect(path)
    end
end

# Searches after posts with their title
#
# @param [String] info The title that is being used for the search
#
# @see DB_Functions#select
post('/search_post') do
    result = select('posts', 'content_title', params[:info], 'id')
    if result == []
        session[:error_msg] = "There is no post with that title"
        redirect('/')
    else
        id = result[0]['id']
        path = '/post/' + id.to_s
        redirect(path)
    end
end

# Searches after posts with their id:s
#
# @param [String] info The id being used in the search
#
# @see DB_Functions#select
post('/search_post_id') do
    result = select('posts', 'id', params[:info])
    if result == []
        session[:error_msg] = "No posts with that id exists"
        redirect('/')
    else
        path = '/post/' + params[:info].to_s
        redirect(path)
    end
    redirect('/')
end