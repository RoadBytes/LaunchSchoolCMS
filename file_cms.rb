require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

set :server, 'webrick'

configure do
  enable :sessions
  set    :session_secret, 'secret'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def create_document(name, content = '')
  File.open(File.join(data_path, name), 'w') do |file|
    file.write(content)
  end
end

def filename_valid?(filename)
  present?(filename) &&
    filename.match(/\.(txt$|md$|markdown$)/)
end

def present?(object)
  object && !object.empty?
end

def signed_in?
  !!session[:username]
end

def redirect_unsigned_users
  unless signed_in?
    session[:error] = 'You must be signed in to do that'
    redirect '/'
  end
end

def load_user_credentials
  credentials_path = if ENV['RACK_ENV'] == 'test'
                       File.expand_path('../test/users.yml', __FILE__)
                     else
                       File.expand_path('../users.yml', __FILE__)
                     end
  YAML.load_file(credentials_path)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def render_file(file_path)
  plain_text = File.read(file_path)

  if file_path =~ /txt$/
    headers['Content-Type'] = 'text/plain'
    plain_text
  else
    render_markdown(plain_text)
  end
end

def valid_sign_in?(username, password)
  credentials   = load_user_credentials
  password_hash = credentials[username]

  return false if password_hash.nil?
  bcrypt_obj = BCrypt::Password.new(password_hash)
  bcrypt_obj == password
end

get '/' do
  if session[:username]
    pattern = File.join(data_path, '*')
    @files = Dir.glob(pattern).map do |path|
      File.basename(path)
    end

    erb :index
  else
    erb :sign_in
  end
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if valid_sign_in?(username, password)
    session[:username] = username
    session[:success]  = 'Welcome'
    redirect '/'
  else
    session[:error] = 'Invalid Credentials'
    status 422
    erb :sign_in
  end
end

post '/signout' do
  session[:username] = nil
  session[:success]  = 'You have been signed out.'

  redirect '/'
end

get '/new' do
  redirect_unsigned_users

  erb :file_new
end

post '/new' do
  redirect_unsigned_users

  new_filename = params[:new_filename].to_s.strip

  if filename_valid? new_filename
    create_document(new_filename, '')
    session[:success] = "#{new_filename} has been created"

    redirect '/'
  else
    session[:error] = 'A name is required ending .txt or .md or .markdown'
    status 422

    erb :file_new
  end
end

get '/:filename' do
  filename  = params[:filename]
  file_path = File.join(data_path, filename)

  if File.file?(file_path)
    render_file(file_path)
  else
    session[:error] = "#{filename} does not exist"
    redirect '/'
  end
end

get '/:filename/edit' do
  redirect_unsigned_users

  @filename = params[:filename]
  file_path = File.join(data_path, @filename)

  if File.file?(file_path)
    @file = File.read(file_path)
    erb :file_edit
  else
    session[:error] = "#{@filename} does not exist"
    redirect '/'
  end
end

post '/:filename/edit' do
  redirect_unsigned_users

  @filename = params[:filename]
  @content  = params[:content]
  file_path = File.join(data_path, @filename)

  if File.file?(file_path)
    session[:success] = "#{@filename} has been updated."
    @file = File.write(file_path, @content)
  else
    session[:error] = "#{@filename} does not exist"
  end

  redirect '/'
end

post '/:filename/delete' do
  redirect_unsigned_users

  filename = params[:filename]
  file_path = File.join(data_path, filename)

  if File.file?(file_path)
    File.delete(file_path)
    session[:success] = "#{filename} was deleted"
  else
    session[:error] = "#{filename} does not exist"
  end

  redirect '/'
end
