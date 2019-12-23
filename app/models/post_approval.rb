class PostApproval < ApplicationRecord
  belongs_to :user
  belongs_to :post, inverse_of: :approvals

  validate :validate_approval
  after_create :approve_post

  def validate_approval
    post.lock!

    if post.is_status_locked?
      errors.add(:post, "is locked and cannot be approved")
    end

    if post.status == "active"
      errors.add(:post, "is already active and cannot be approved")
    end

    if post.uploader == user
      errors.add(:base, "You cannot approve a post you uploaded")
    end

    if post.approved_by?(user)
      errors.add(:base, "You have previously approved this post and cannot approve it again")
    end
  end

  def approve_post
    ModAction.log("undeleted post ##{post_id}", :post_undelete) if post.is_deleted

    post.flags.each(&:resolve!)
    post.update(approver: user, is_flagged: false, is_pending: false, is_deleted: false)
  end

  def self.search(params)
    q = super
    q = q.search_attributes(params, :user, :post)
    q.apply_default_order(params)
  end
end
