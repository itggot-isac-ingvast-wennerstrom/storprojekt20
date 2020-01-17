require 'slim'
require 'sinatra'
require 'sqlite3'

enable :sessions

get('/') do
    slim(:main)
end