require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

set :server, 'webrick'

configure do
  enable :sessions
  set    :session_secret, 'secret'
end

root = File.expand_path('..', __FILE__)

get '/' do
  @files = Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end

  erb :index
end

get '/:filename' do
  filename  = params[:filename]
  file_path = root + '/data/' + filename

  if File.file?(file_path)
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  else
    session[:error] = "#{filename} does not exists"
    redirect '/'
  end
end
