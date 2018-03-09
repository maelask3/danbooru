require "test_helper"

module Explore
  class PostsControllerTest < ActionDispatch::IntegrationTest
    context "in all cases" do
      setup do
        CurrentUser.user = FactoryBot.create(:user)
        CurrentUser.ip_addr = "127.0.0.1"
        FactoryBot.create(:post)
      end

      context "#popular" do
        should "render" do
          get :popular
          assert_response :success
        end
      end

      context "#searches" do
        should "render" do
          get :searches
          assert_response :success
        end
      end

      context "#missed_searches" do
        should "render" do
          get :missed_searches
          assert_response :success
        end
      end

      context "#intro" do
        should "render" do
          get :intro
          assert_response :success
        end
      end
    end
  end
end
