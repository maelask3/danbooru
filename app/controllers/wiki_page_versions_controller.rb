class WikiPageVersionsController < ApplicationController
  respond_to :html, :xml, :json
  layout "sidebar"

  def index
    @wiki_page_versions = WikiPageVersion.paginated_search(params)
    respond_with(@wiki_page_versions)
  end

  def show
    @wiki_page_version = WikiPageVersion.find(params[:id])
    respond_with(@wiki_page_version)
  end

  def diff
    if params[:thispage].blank? || params[:otherpage].blank?
      redirect_back fallback_location: wiki_pages_path, notice: "You must select two versions to diff"
      return
    end

    @thispage = WikiPageVersion.find(params[:thispage])
    @otherpage = WikiPageVersion.find(params[:otherpage])
  end
end
