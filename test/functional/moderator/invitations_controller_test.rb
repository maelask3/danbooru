require 'test_helper'

module Moderator
  class InvitationsControllerTest < ActionDispatch::IntegrationTest
    context "The invitations controller" do
      setup do
        @mod = FactoryBot.create(:moderator_user)
        CurrentUser.user = @mod
        CurrentUser.ip_addr = "127.0.0.1"

        @user_1 = FactoryBot.create(:user)
        @user_2 = FactoryBot.create(:user, :inviter_id => @mod.id)
      end

      should "render the new page" do
        get_authenticated :new:_path, @mod, params: {:invitation => {:name => @user_1.name}}
        assert_response :success
      end

      should "create a new invite" do
        post_authenticated :create:_path, @mod, params: {:invitation => {:user_id => @user_1.id, :level => User::Levels::BUILDER, :can_upload_free => "1"}}
        assert_redirected_to(moderator_invitations_path)
        @user_1.reload
        assert_equal(User::Levels::BUILDER, @user_1.level)
        assert_equal(true, @user_1.can_upload_free?)
      end

      should "list invites" do
        get :index, {}, {:user_id => @mod.id}
        assert_response :success
      end
    end
  end
end
