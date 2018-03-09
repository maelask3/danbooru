require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super

    CurrentUser.user = FactoryBot.create(:mod_user)
    CurrentUser.ip_addr = "127.0.0.1"
    session[:user_id] = CurrentUser.user.id

    @users = FactoryBot.create_list(:contributor_user, 2)
    @posts = @users.map { |u| FactoryBot.create(:post, uploader: u) }
  end

  def teardown
    super

    CurrentUser.user = nil
    CurrentUser.ip_addr = nil
    session[:user_id] = nil
  end

  context "The reports controller" do
    context "uploads action" do
      should "render" do
        get :uploads
        assert_response :success
      end
    end

    context "similar_users action" do
      should "render" do
        #get :similar_users
        #assert_response :success
      end
    end

    context "post_versions action" do
      should "render" do
        get :post_versions
        assert_response :success
      end
    end
  end
end
