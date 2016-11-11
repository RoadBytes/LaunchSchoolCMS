require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

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

get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :index
end

get '/:filename' do
  filename  = params[:filename]
  file_path = File.join(data_path, filename)

  if File.file?(file_path)
    render_file(file_path)
  else
    session[:error] = "#{filename} does not exists"
    redirect '/'
  end
end

get '/:filename/edit' do
  @filename = params[:filename]
  file_path = File.join(data_path, @filename)

  if File.file?(file_path)
    @file = File.read(file_path)
    erb :file_edit
  else
    session[:error] = "#{@filename} does not exists"
    redirect '/'
  end
end

post '/:filename/edit' do
  @filename = params[:filename]
  @content  = params[:content]
  file_path = File.join(data_path, @filename)

  if File.file?(file_path)
    session[:success] = "#{@filename} has been updated."
    @file = File.write(file_path, @content)
  else
    session[:error] = "#{@filename} does not exists"
  end

  redirect '/'
end
