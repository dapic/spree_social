Spree.user_class.class_eval do
  has_many :user_authentications, dependent: :destroy

  devise :omniauthable

  def apply_omniauth(omniauth)
    if ["facebook", 'google_oauth2'].include? omniauth['provider']
      self.email = omniauth['info']['email'] if email.blank?
    end
    user_authentications.build(provider: omniauth['provider'], uid: omniauth['uid'])
  end

  # this method DIRECTLY REPLACES the method in spree_auth_devise's "user" model file
  # there is another one defined in "validable.rb" (a devise module) and that is a "super" of this one
  # TODO: not sure how this behaves when resetting passwords
  def password_required?
    return false if ( !user_authentications.empty? || awaiting_phone_verification? )
    super
  end
end
