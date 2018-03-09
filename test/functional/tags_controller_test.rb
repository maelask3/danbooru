require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  context "The tags controller" do
    setup do
      @user = FactoryBot.create(:builder_user)
      CurrentUser.user = @user
      CurrentUser.ip_addr = "127.0.0.1"

      @tag = FactoryBot.create(:tag, name: "touhou", category: Tag.categories.copyright, post_count: 1)
    end

    teardown do
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end

    context "edit action" do
      should "render" do
        get :edit, {:id => @tag.id}, {:user_id => @user.id}
        assert_response :success
      end
    end

    context "index action" do
      should "render" do
        get :index
        assert_response :success
      end

      context "with search parameters" do
        should "render" do
          get :index, {:search => {:name_matches => "touhou"}}
          assert_response :success
        end
      end

      context "with blank search parameters" do
        should "strip the blank parameters with a redirect" do
          get :index, { search: { name: "touhou", category: "" } }

          assert_redirected_to tags_path(search: { name: "touhou" })
        end
      end
    end

    context "autocomplete action" do
      should "render" do
        get :autocomplete, { search: { name_matches: "t" }, format: :json }
        assert_response :success
      end
    end

    context "show action" do
      should "render" do
        get :show, {:id => @tag.id}
        assert_response :success
      end
    end

    context "update action" do
      setup do
        @mod = FactoryBot.create(:moderator_user)
      end

      should "update the tag" do
        post :update, {:id => @tag.id, :tag => {:category => Tag.categories.general}}, {:user_id => @user.id}
        assert_redirected_to tag_path(@tag)
        assert_equal(Tag.categories.general, @tag.reload.category)
      end

      should "lock the tag for a moderator" do
        CurrentUser.user = @mod
        post :update, { id: @tag.id, tag: { is_locked: true } }, { user_id: @mod.id }

        assert_redirected_to @tag
        assert_equal(true, @tag.reload.is_locked)
      end

      should "not lock the tag for a user" do
        post :update, {id: @tag.id, tag: { is_locked: true }}, { user_id: @user.id }

        assert_equal(false, @tag.reload.is_locked)
      end

      context "for a tag with >50 posts" do
        setup do
          @tag.update(post_count: 100)
        end

        should "not update the category for a member" do
          CurrentUser.user = FactoryBot.create(:member_user)
          post :update, {id: @tag.id, tag: { category: Tag.categories.general }}, {user_id: CurrentUser.id}

          assert_not_equal(Tag.categories.general, @tag.reload.category)
        end

        should "update the category for a builder" do
          post :update, {id: @tag.id, tag: { category: Tag.categories.general }}, {user_id: @user.id}

          assert_redirected_to @tag
          assert_equal(Tag.categories.general, @tag.reload.category)
        end
      end

      should "not change category when the tag is too large to be changed by a builder" do
        @tag.update(category: Tag.categories.general, post_count: 1001)
        post :update, {:id => @tag.id, :tag => {:category => Tag.categories.artist}}, {:user_id => @user.id}

        assert_response :forbidden
        assert_equal(Tag.categories.general, @tag.reload.category)
      end
    end
  end
end
