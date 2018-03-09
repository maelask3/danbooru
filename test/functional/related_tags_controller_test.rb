require 'test_helper'

class RelatedTagsControllerTest < ActionDispatch::IntegrationTest
  context "The related tags controller" do
    context "show action" do
      should "work" do
        get :show, { query: "touhou" }
        assert_response :success
      end
    end
  end
end
