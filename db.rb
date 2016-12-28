require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'
require 'yaml'

# an online database, that allow user to write, edit, delete, duplicate , read text file.
# there is a sign in , sign up and sign out function. 
root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def require_signin
  unless session[:username] 
    session[:message] = "This page requires user sign in."
    redirect "/"
  end
end

get "/" do
  @files = Dir.glob(root + "/data/*").map do |full_path|
    File.basename(full_path)
  end
  erb :index
end

get '/:filename/edit' do
  require_signin
  file_path = root + '/data/' + params[:filename]
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end

get "/create" do
  require_signin
  erb :new
end

get "/:filename/duplicate" do
  require_signin
  file_path = root + '/data/' + params[:filename]
  content = File.read(file_path)
  
  File.write(file_path << "(copy)", content)
  redirect "/"
end

get "/users/signup" do
  erb :signup
end

get "/users/signin" do
  # render sign in page
  erb :signin
end

get "/:filename" do
  file_path = root + '/data/' + params[:filename]
  # handle exceptions
  if File.file?(file_path)
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  else
  # happy path
    session[:message] = "#{params[:filename]} doesn't exist."
    redirect "/"
  end
end

post "/new" do
  file_path = root + '/data/' + params[:filename]
  
  if File.exist?(file_path)
    session[:message] = "#{params[:filename]} already exist."
  elsif File.extname(file_path) != '.txt'
    session[:message] = "Must be txt file."
  else
    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created"
  end
  redirect "/"
end

post "/users/signup" do
  username_hash = YAML.load_file(root + "/username.yml")
  
  username = params[:username]
  if username.strip.empty?
    session[:message] = "username must not be empty"
    erb :signup
  elsif username_hash.has_key?(username)
    session[:message] = "username already exist."
    erb :signup
  else
    username_hash[username] = params[:password]
    File.write(root + "/username.yml", username_hash.to_yaml)
    session[:message] = "Account successfully created."
    redirect "/"
  end
end

post "/users/signin" do
  username_hash = YAML.load_file(root + '/username.yml')
  username = params[:username]
  if username_hash.has_key?(username) && username_hash[username] == params[:password]
    session[:message] = "Signed in as #{username}. Welcome."
    session[:username] = username
    redirect "/"
  else
    session[:message] = "Invalid username or password."
    redirect "/"
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "Logged out."
  redirect "/"
end

post "/:filename/delete" do
  require_signin
  file_path = root + '/data/' + params[:filename]
  File.delete(file_path)
  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end

post "/:filename" do
  require_signin
  file_path = root + '/data/' + params[:filename]
  File.write(file_path, params[:content])
  
  session[:message] = "Data updated."
  redirect '/'
end

