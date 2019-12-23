class TagImplicationsController < ApplicationController
  before_action :admin_only, :only => [:new, :create, :approve]
  respond_to :html, :xml, :json, :js

  def show
    @tag_implication = TagImplication.find(params[:id])
    respond_with(@tag_implication)
  end

  def edit
    @tag_implication = TagImplication.find(params[:id])
  end

  def update
    @tag_implication = TagImplication.find(params[:id])

    if @tag_implication.is_pending? && @tag_implication.editable_by?(CurrentUser.user)
      @tag_implication.update(tag_implication_params)
    end

    respond_with(@tag_implication)
  end

  def index
    @tag_implications = TagImplication.includes(:antecedent_tag, :consequent_tag, :approver).paginated_search(params, count_pages: true)
    respond_with(@tag_implications)
  end

  def destroy
    @tag_implication = TagImplication.find(params[:id])
    raise User::PrivilegeError unless @tag_implication.deletable_by?(CurrentUser.user)

    @tag_implication.reject!
    respond_with(@tag_implication, location: tag_implications_path, notice: "Tag implication was deleted")
  end

  def approve
    @tag_implication = TagImplication.find(params[:id])
    @tag_implication.approve!(approver: CurrentUser.user)
    respond_with(@tag_implication, :location => tag_implication_path(@tag_implication))
  end

  private

  def tag_implication_params
    params.require(:tag_implication).permit(%i[antecedent_name consequent_name forum_topic_id skip_secondary_validations])
  end
end
