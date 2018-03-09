require 'test_helper'

class PostVersionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super

    @user = FactoryBot.create(:user)
    CurrentUser.user = @user
    CurrentUser.ip_addr = "127.0.0.1"
  end

  def teardown
    super

    CurrentUser.user = nil
    CurrentUser.ip_addr = nil
  end

  context "The post versions controller" do
    context "index action" do
      setup do
        @post = FactoryBot.create(:post)
        @post.update_attributes(:tag_string => "1 2", :source => "xxx")
        @post.update_attributes(:tag_string => "2 3", :rating => "e")
      end

      should "list all versions" do
        get :index, {}, {:user_id => @user.id}
        assert_response :success
        assert_not_nil(assigns(:post_versions))
      end

      should "list all versions that match the search criteria" do
        get_authenticated :index:_path, @user, params: {:search => {:post_id => @post.id}}
        assert_response :success
        assert_not_nil(assigns(:post_versions))
      end
    end
  end
end
