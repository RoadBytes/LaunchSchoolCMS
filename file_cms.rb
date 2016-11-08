require 'sinatra'
require 'sinatra/reloader' if development?

set :server, 'webrick'

get '/' do
  'Getting Started'
end
