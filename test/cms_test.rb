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

  def session
    last_request.env['rack.session']
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def test_index_not_signed_in
    create_document 'about.md'
    create_document 'changes.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "<input type='submit' value='Sign In'>"
    assert_nil session[:username]
    refute_includes last_response.body, 'about.md'
    refute_includes last_response.body, 'changes.txt'
  end

  def test_index_signed_in
    create_document 'about.md'
    create_document 'changes.txt'

    get '/', {}, { 'rack.session' => { username: 'admin' } }

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "<a href='/changes.txt/edit'>Edit</a>"
    assert_includes last_response.body, "<a href='/new'>New Document</a>"
    assert_includes last_response.body, "action='about.md/delete"
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_signin_success
    create_document 'about.md'
    create_document 'changes.txt'

    post '/signin', username: 'admin', password: 'secret'

    assert_equal 302, last_response.status
    assert_equal 'Welcome', session[:success]
    assert_equal 'admin', session[:username]

    get last_response['Location']

    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'Signed in as admin'
    assert_includes last_response.body, 'Sign Out'
  end

  def test_signin_fail
    create_document 'about.md'
    create_document 'changes.txt'

    post '/signin', username: 'admin', password: 'incorrect'

    assert_equal 'Invalid Credentials', session[:error]

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_nil session[:username]
    refute_includes last_response.body, 'about.md'
    refute_includes last_response.body, 'changes.txt'
  end

  def test_signout
    create_document 'about.md'
    create_document 'changes.txt'

    post '/signout'

    assert_equal 302, last_response.status
    assert_equal 'You have been signed out.', session[:success]

    get last_response['Location']

    assert_nil session[:username]
    refute_includes last_response.body, 'about.md'
    refute_includes last_response.body, 'changes.txt'
  end

  def test_text_document_signed_in
    create_document 'history.txt', 'It was the best of times'

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_equal last_response.body, 'It was the best of times'
  end

  def test_nonexistent_documents
    get '/nonexistent.txt'

    assert_equal 302, last_response.status
    assert_equal 'nonexistent.txt does not exist', session[:error]
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
    assert_equal 'temp.md has been updated.', session[:success]

    get '/temp.md'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end

  def test_get_new_file
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Add a new document:'
  end

  def test_post_new_file
    post '/new', new_filename: 'new.md'

    assert_equal 302, last_response.status
    assert_equal 'new.md has been created', session[:success]

    get '/', {}, { 'rack.session' => { username: 'admin' } }
    assert_includes last_response.body, "href='/new.md'"
  end

  def test_post_new_blank_filename
    post '/new', new_filename: ''

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'A name is required'
  end

  def test_delete_documents
    create_document 'to_be_deleted.txt'

    post '/to_be_deleted.txt/delete'

    assert_equal 302, last_response.status
    assert_equal 'to_be_deleted.txt was deleted', session[:success]

    get '/'

    refute_includes last_response.body,
                    "<a href='/to_be_deleted.txt'>to_be_deleted.txt</a>"
  end
end
