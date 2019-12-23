class ArtistsController < ApplicationController
  respond_to :html, :xml, :json, :js
  before_action :member_only, :except => [:index, :show, :show_or_new, :banned]
  before_action :admin_only, :only => [:ban, :unban]
  before_action :load_artist, :only => [:ban, :unban, :show, :edit, :update, :destroy, :undelete]

  def new
    @artist = Artist.new_with_defaults(artist_params(:new))
    respond_with(@artist)
  end

  def edit
    respond_with(@artist)
  end

  def banned
    redirect_to artists_path(search: { is_banned: "true", order: "updated_at" }, format: request.format.symbol)
  end

  def ban
    @artist.ban!
    redirect_to(artist_path(@artist), :notice => "Artist was banned")
  end

  def unban
    @artist.unban!
    redirect_to(artist_path(@artist), :notice => "Artist was unbanned")
  end

  def index
    # XXX
    params[:search][:name] = params.delete(:name) if params[:name]

    @artists = Artist.includes(:urls).paginated_search(params)
    @artists = @artists.includes(:tag) if request.format.html?
    @artists = @artists.includes(:urls) if !request.format.html?

    if params[:redirect].to_s.truthy? && @artists.one? && @artists.first.name == Artist.normalize_name(params[:search][:any_name_or_url_matches])
      redirect_to @artists.first
    else
      respond_with @artists
    end
  end

  def show
    @artist = Artist.find(params[:id])
    @post_set = PostSets::Artist.new(@artist)
    respond_with(@artist)
  end

  def create
    @artist = Artist.create(artist_params)
    respond_with(@artist)
  end

  def update
    @artist.update(artist_params)
    flash[:notice] = @artist.valid? ? "Artist updated" : @artist.errors.full_messages.join("; ")
    respond_with(@artist)
  end

  def destroy
    @artist.update_attribute(:is_active, false)
    redirect_to(artist_path(@artist), :notice => "Artist deleted")
  end

  def revert
    @artist = Artist.find(params[:id])
    @version = @artist.versions.find(params[:version_id])
    @artist.revert_to!(@version)
    respond_with(@artist)
  end

  def show_or_new
    @artist = Artist.find_by_name(params[:name])

    if params[:name].blank?
      redirect_to new_artist_path(artist_params(:new))
    elsif @artist.present?
      redirect_to artist_path(@artist)
    else
      @artist = Artist.new(name: params[:name])
      @post_set = PostSets::Artist.new(@artist)
      respond_with(@artist)
    end
  end

  private

  def load_artist
    @artist = Artist.find(params[:id])
  end

  def artist_params(context = nil)
    permitted_params = %i[name other_names other_names_string group_name url_string notes is_active]
    permitted_params << :source if context == :new

    params.fetch(:artist, {}).permit(permitted_params)
  end
end
