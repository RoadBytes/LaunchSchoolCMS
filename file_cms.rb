require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

set :server, 'webrick'

root = File.expand_path('..', __FILE__)

get '/' do
  @files = Dir.glob(root + '/data/*').map do |path|
    File.basename(path)
  end

  erb :index
end

get '/:filename' do
  file_path = root + '/data/' + params[:filename]

  headers['Content-Type'] = 'text/plain; charset=utf8'
  File.read file_path
end
