ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../file_cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'history.txt'
    assert_includes last_response.body, "<a href='/history.txt/edit'>Edit</a>"
    assert_includes last_response.body, 'about.txt'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'markdown.md'
  end

  def test_text_document
    root      = File.expand_path('../..', __FILE__)
    file_path = root + '/data/' + 'history.txt'
    history   = File.read file_path

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_equal history, last_response.body
  end

  def test_nonexistent_documents
    get '/nonexistent.txt'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response.location

    get last_response.location

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'nonexistent.txt does not exist'
  end

  def test_markdown_document
    get '/markdown.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_editing_markdown_document
    get '/markdown.md/edit'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Edit content for markdown.md'
  end

  def create_new_temp_file
    root      = File.expand_path('../..', __FILE__)
    file_path = root + '/data/' + 'temp.md'

    file      = File.new(file_path, 'w')
    file.write('# Temp file here')
    file.close
  end

  def delete_temp_file
    root      = File.expand_path('../..', __FILE__)
    file_path = root + '/data/' + 'temp.md'

    File.delete file_path
  end

  def test_updating_markdown_document
    create_new_temp_file

    post '/temp.md/edit', content: 'new content'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_includes last_response.body, 'temp.md has been updated.'

    get '/temp.md'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'

    delete_temp_file
  end
end
