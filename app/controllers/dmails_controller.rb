class DmailsController < ApplicationController
  respond_to :html, :xml, :json
  before_action :member_only, except: [:index, :show, :destroy, :mark_all_as_read]
  before_action :gold_only, only: [:ham, :spam]

  def new
    if params[:respond_to_id]
      parent = Dmail.find(params[:respond_to_id])
      check_privilege(parent)
      @dmail = parent.build_response(:forward => params[:forward])
    else
      @dmail = Dmail.new(create_params)
    end

    respond_with(@dmail)
  end

  def index
    if params[:folder] && params[:set_default_folder]
      cookies.permanent[:dmail_folder] = params[:folder]
    end
    @dmails = Dmail.active.visible.paginated_search(params, count_pages: true)
    respond_with(@dmails)
  end

  def show
    @dmail = Dmail.find(params[:id])
    check_privilege(@dmail)
    @dmail.mark_as_read!
    respond_with(@dmail)
  end

  def create
    @dmail = Dmail.create_split(create_params)
    respond_with(@dmail)
  end

  def destroy
    @dmail = Dmail.find(params[:id])
    check_privilege(@dmail)
    @dmail.mark_as_read!
    @dmail.destroy
    redirect_to dmails_path, :notice => "Message destroyed"
  end

  def mark_all_as_read
    Dmail.visible.unread.each do |x|
      x.update_column(:is_read, true)
    end
    CurrentUser.user.update(has_mail: false, unread_dmail_count: 0)
  end

  def spam
    @dmail = Dmail.find(params[:id])
    @dmail.update_column(:is_spam, true)
  end

  def ham
    @dmail = Dmail.find(params[:id])
    @dmail.update_column(:is_spam, false)
  end

  private

  def check_privilege(dmail)
    if !dmail.visible_to?(CurrentUser.user, params[:key])
      raise User::PrivilegeError
    end
  end

  def create_params
    params.fetch(:dmail, {}).permit(:title, :body, :to_name, :to_id)
  end
end
