require File.dirname(__FILE__) + '/../test_helper'
require 'statements_controller'

# Re-raise errors caught by the controller.
class StatementsController; def rescue_action(e) raise e end; end

class StatementsControllerTest < Test::Unit::TestCase
  fixtures :statements

  def setup
    @controller = StatementsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:statements)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:statement)
    assert assigns(:statement).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:statement)
  end

  def test_create
    num_statements = Statement.count

    post :create, :statement => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_statements + 1, Statement.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:statement)
    assert assigns(:statement).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Statement.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Statement.find(1)
    }
  end
end
