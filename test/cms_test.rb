ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../file_cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "<a href='/changes.txt/edit'>Edit</a>"
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_text_document
    create_document 'history.txt', 'It was the best of times'

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_equal last_response.body, 'It was the best of times'
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
    create_document 'markdown.md', '# Ruby is...'

    get '/markdown.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<h1>Ruby is...</h1>'
  end

  def test_editing_markdown_document
    create_document 'markdown.md', '# Ruby is...'

    get '/markdown.md/edit'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Edit content for markdown.md'
  end

  def test_updating_markdown_document
    create_document 'temp.md', '# Ruby is...'

    post '/temp.md/edit', content: 'new content'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_includes last_response.body, 'temp.md has been updated.'

    get '/temp.md'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end
end
