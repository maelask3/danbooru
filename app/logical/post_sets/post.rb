module PostSets
  class Post < PostSets::Base
    MAX_PER_PAGE = 200
    attr_reader :tag_array, :page, :raw, :random, :post_count, :format

    def initialize(tags, page = 1, per_page = nil, options = {})
      @tag_array = Tag.scan_query(tags)
      @page = page
      @per_page = per_page
      @raw = options[:raw].present?
      @random = options[:random].present?
      @format = options[:format] || "html"
    end

    def tag_string
      @tag_string ||= tag_array.uniq.join(" ")
    end

    def humanized_tag_string
      tag_array.slice(0, 25).join(" ").tr("_", " ")
    end

    def unordered_tag_array
      tag_array.reject {|tag| tag =~ /\Aorder:/i }
    end

    def has_blank_wiki?
      tag.present? && !wiki_page.present?
    end

    def wiki_page
      return nil unless tag.present? && tag.wiki_page.present?
      return nil unless !tag.wiki_page.is_deleted? && tag.wiki_page.visible?
      tag.wiki_page
    end

    def tag
      return nil if !is_single_tag?
      @tag ||= Tag.find_by(name: Tag.normalize_name(tag_string))
    end

    def artist
      return nil unless tag.present? && tag.category == Tag.categories.artist
      return nil unless tag.artist.present? && tag.artist.is_active? && tag.artist.visible?
      tag.artist
    end

    def pool_name
      @pool_name ||= Tag.has_metatag?(tag_array, :ordpool, :pool)
    end

    def has_pool?
      is_single_tag? && pool_name && pool
    end

    def pool
      ::Pool.find_by_name(pool_name)
    end

    def favgroup_name
      @favgroup_name ||= Tag.has_metatag?(tag_array, :favgroup)
    end

    def has_favgroup?
      is_single_tag? && favgroup_name && favgroup
    end

    def favgroup
      ::FavoriteGroup.find_by_name(favgroup_name)
    end

    def has_deleted?
      tag_string !~ /status/ && ::Post.tag_match("#{tag_string} status:deleted").where("true /* PostSets::Post#has_deleted */").exists?
    end

    def has_explicit?
      posts.any? {|x| x.rating == "e"}
    end

    def hidden_posts
      posts.reject { |p| p.visible? }
    end

    def banned_posts
      posts.select { |p| p.banblocked? }
    end

    def censored_posts
      posts.select { |p| p.levelblocked? && !p.banblocked? }
    end

    def safe_posts
      posts.select { |p| p.safeblocked? && !p.levelblocked? && !p.banblocked? }
    end

    def per_page
      (@per_page || Tag.has_metatag?(tag_array, :limit) || CurrentUser.user.per_page).to_i.clamp(0, MAX_PER_PAGE)
    end

    def is_random?
      random || Tag.has_metatag?(tag_array, :order) == "random"
    end

    def use_sequential_paginator?
      unknown_post_count? && !CurrentUser.is_gold?
    end

    def get_post_count
      if %w(json atom xml).include?(format.downcase)
        # no need to get counts for formats that don't use a paginator
        return Danbooru.config.blank_tag_search_fast_count
      else
        ::Post.fast_count(tag_string)
      end
    end

    def get_random_posts
      per_page.times.inject([]) do |all, x|
        all << ::Post.tag_match(tag_string).random
      end.compact.uniq
    end

    def posts
      @posts ||= begin
        @post_count = get_post_count

        if is_random?
          temp = get_random_posts
        elsif raw
          temp = ::Post.raw_tag_match(tag_string).order("posts.id DESC").where("true /* PostSets::Post#posts:1 */").paginate(page, :count => post_count, :limit => per_page)
        else
          temp = ::Post.tag_match(tag_string).where("true /* PostSets::Post#posts:2 */").paginate(page, :count => post_count, :limit => per_page)
        end

        # HACK: uploader_name is needed in api responses and in data-uploader attribs (visible to mods only).
        temp = temp.includes(:uploader) if !is_random? && (format.to_sym != :html || CurrentUser.is_moderator?)

        temp.each # hack to force rails to eager load
        temp
      end
    end

    def unknown_post_count?
      post_count == Danbooru.config.blank_tag_search_fast_count
    end

    def hide_from_crawler?
      return true if current_page > 1
      return false if is_empty_tag? || is_simple_tag? || tag_string == "order:rank"
      true
    end

    def is_single_tag?
      tag_array.size == 1
    end

    def is_simple_tag?
      Tag.is_simple_tag?(tag_string)
    end

    def is_empty_tag?
      tag_array.empty?
    end

    def is_pattern_search?
      is_single_tag? && tag_string =~ /\*/ && tag_array.none? {|x| x =~ /^-?source:.+/}
    end

    def current_page
      [page.to_i, 1].max
    end

    def is_saved_search?
      tag_string =~ /search:/
    end

    def presenter
      @presenter ||= ::PostSetPresenters::Post.new(self)
    end

    def best_post
      # be smarter about this in the future
      posts.reject(&:is_deleted).select(&:visible?).max_by(&:fav_count)
    end
  end
end
