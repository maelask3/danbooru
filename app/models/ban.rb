class Ban < ApplicationRecord
  after_create :create_feedback
  after_create :update_user_on_create
  after_create :create_ban_mod_action
  after_destroy :update_user_on_destroy
  after_destroy :create_unban_mod_action
  belongs_to :user
  belongs_to :banner, :class_name => "User"
  validate :user_is_inferior
  validates_presence_of :reason, :duration
  before_validation :initialize_banner_id, :on => :create

  scope :unexpired, -> { where("bans.expires_at > ?", Time.now) }
  scope :expired, -> { where("bans.expires_at <= ?", Time.now) }

  def self.is_banned?(user)
    exists?(["user_id = ? AND expires_at > ?", user.id, Time.now])
  end

  def self.reason_matches(query)
    if query =~ /\*/
      where("lower(bans.reason) LIKE ?", query.mb_chars.downcase.to_escaped_for_sql_like)
    else
      where("bans.reason @@ plainto_tsquery(?)", query)
    end
  end

  def self.search(params)
    q = super

    q = q.search_attributes(params, :banner, :user, :expires_at, :reason)
    q = q.text_attribute_matches(:reason, params[:reason_matches])

    q = q.expired if params[:expired].to_s.truthy?
    q = q.unexpired if params[:expired].to_s.falsy?

    case params[:order]
    when "expires_at_desc"
      q = q.order("bans.expires_at desc")
    else
      q = q.apply_default_order(params)
    end

    q
  end

  def self.prune!
    expired.includes(:user).find_each do |ban|
      ban.user.unban! if ban.user.ban_expired?
    end
  end

  def initialize_banner_id
    self.banner_id = CurrentUser.id if self.banner_id.blank?
  end

  def user_is_inferior
    if user
      if user.is_admin?
        errors[:base] << "You can never ban an admin."
        false
      elsif user.is_moderator? && banner.is_admin?
        true
      elsif user.is_moderator?
        errors[:base] << "Only admins can ban moderators."
        false
      elsif banner.is_admin? || banner.is_moderator?
        true
      else
        errors[:base] << "No one else can ban."
        false
      end
    end
  end

  def update_user_on_create
    user.update!(is_banned: true)
  end

  def update_user_on_destroy
    user.update_attribute(:is_banned, false)
  end

  def user_name
    user ? user.name : nil
  end

  def user_name=(username)
    self.user = User.find_by_name(username)
  end

  def duration=(dur)
    self.expires_at = dur.to_i.days.from_now
    @duration = dur
  end

  attr_reader :duration

  def humanized_duration
    ApplicationController.helpers.distance_of_time_in_words(created_at, expires_at)
  end

  def expired?
    expires_at < Time.now
  end

  def create_feedback
    user.feedback.create!(creator: banner, category: "negative", body: "Banned for #{humanized_duration}: #{reason}")
  end

  def create_ban_mod_action
    ModAction.log(%{Banned <@#{user_name}> for #{humanized_duration}: #{reason}}, :user_ban)
  end

  def create_unban_mod_action
    ModAction.log(%{Unbanned <@#{user_name}>}, :user_unban)
  end
end
