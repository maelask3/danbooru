class Comment < ApplicationRecord
  include Mentionable

  validate :validate_creator_is_not_limited, :on => :create
  validate :validate_comment_is_not_spam, on: :create
  validates_presence_of :body, :message => "has no content"
  belongs_to :post
  belongs_to_creator
  belongs_to_updater
  has_many :votes, :class_name => "CommentVote", :dependent => :destroy
  after_create :update_last_commented_at_on_create
  after_update(:if => ->(rec) {(!rec.is_deleted? || !rec.saved_change_to_is_deleted?) && CurrentUser.id != rec.creator_id}) do |rec|
    ModAction.log("comment ##{rec.id} updated by #{CurrentUser.name}", :comment_update)
  end
  after_save :update_last_commented_at_on_destroy, :if => ->(rec) {rec.is_deleted? && rec.saved_change_to_is_deleted?}
  after_save(:if => ->(rec) {rec.is_deleted? && rec.saved_change_to_is_deleted? && CurrentUser.id != rec.creator_id}) do |rec|
    ModAction.log("comment ##{rec.id} deleted by #{CurrentUser.name}", :comment_delete)
  end
  mentionable(
    :message_field => :body,
    :title => ->(user_name) {"#{creator.name} mentioned you in a comment on post ##{post_id}"},
    :body => ->(user_name) {"@#{creator.name} mentioned you in a \"comment\":/posts/#{post_id}#comment-#{id} on post ##{post_id}:\n\n[quote]\n#{DText.excerpt(body, "@" + user_name)}\n[/quote]\n"}
  )

  api_attributes including: [:creator_name, :updater_name]

  module SearchMethods
    def deleted
      where("comments.is_deleted = true")
    end

    def undeleted
      where("comments.is_deleted = false")
    end

    def search(params)
      q = super

      q = q.search_attributes(params, :post, :creator, :updater, :is_deleted, :is_sticky, :do_not_bump_post, :body, :score)
      q = q.text_attribute_matches(:body, params[:body_matches], index_column: :body_index)

      case params[:order]
      when "post_id", "post_id_desc"
        q = q.order("comments.post_id DESC, comments.id DESC")
      when "score", "score_desc"
        q = q.order("comments.score DESC, comments.id DESC")
      when "updated_at", "updated_at_desc"
        q = q.order("comments.updated_at DESC")
      else
        q = q.apply_default_order(params)
      end

      q
    end
  end

  module VoteMethods
    def vote!(val)
      numerical_score = (val == "up") ? 1 : -1
      vote = votes.create!(:score => numerical_score)

      if vote.is_positive?
        update_column(:score, score + 1)
      elsif vote.is_negative?
        update_column(:score, score - 1)
      end

      return vote
    end

    def unvote!
      vote = votes.where("user_id = ?", CurrentUser.user.id).first

      if vote
        if vote.is_positive?
          update_column(:score, score - 1)
        else
          update_column(:score, score + 1)
        end

        vote.destroy
      else
        raise CommentVote::Error.new("You have not voted for this comment")
      end
    end
  end

  extend SearchMethods
  include VoteMethods

  def validate_creator_is_not_limited
    if creator.is_comment_limited? && !do_not_bump_post?
      errors.add(:base, "You can only post #{Danbooru.config.member_comment_limit} comments per hour")
    elsif !creator.can_comment?
      errors.add(:base, "You can not post comments within 1 week of sign up")
    end
  end

  def validate_comment_is_not_spam
    errors[:base] << "Failed to create comment" if SpamDetector.new(self).spam?
  end

  def update_last_commented_at_on_create
    Post.where(:id => post_id).update_all(:last_commented_at => created_at)
    if Comment.where("post_id = ?", post_id).count <= Danbooru.config.comment_threshold && !do_not_bump_post?
      Post.where(:id => post_id).update_all(:last_comment_bumped_at => created_at)
    end
  end

  def update_last_commented_at_on_destroy
    other_comments = Comment.where("post_id = ? and id <> ?", post_id, id).order("id DESC")
    if other_comments.count == 0
      Post.where(:id => post_id).update_all(:last_commented_at => nil)
    else
      Post.where(:id => post_id).update_all(:last_commented_at => other_comments.first.created_at)
    end

    other_comments = other_comments.where("do_not_bump_post = FALSE")
    if other_comments.count == 0
      Post.where(:id => post_id).update_all(:last_comment_bumped_at => nil)
    else
      Post.where(:id => post_id).update_all(:last_comment_bumped_at => other_comments.first.created_at)
    end
  end

  def editable_by?(user)
    creator_id == user.id || user.is_moderator?
  end

  def voted_by?(user)
    return false if user.is_anonymous?
    user.id.in?(votes.map(&:user_id))
  end

  def visibility(user)
    return :invisible if is_deleted? && !user.is_moderator?
    return :hidden if is_deleted? && user.is_moderator?
    return :hidden if score < user.comment_threshold && !is_sticky?
    return :visible
  end

  def self.hidden(user)
    select { |comment| comment.visibility(user) == :hidden }
  end

  def self.visible(user)
    select { |comment| comment.visibility(user) == :visible }
  end

  def creator_name
    creator.name
  end

  def updater_name
    updater.name
  end

  def delete!
    update(is_deleted: true)
  end

  def undelete!
    update(is_deleted: false)
  end

  def quoted_response
    DText.quote(body, creator.name)
  end
end
