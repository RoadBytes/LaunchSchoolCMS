require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'redcarpet'

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

get '/:filename' do
  filename  = params[:filename]
  file_path = root + '/data/' + filename

  if File.file?(file_path)
    render_file(file_path)
  else
    session[:error] = "#{filename} does not exists"
    redirect '/'
  end
end
