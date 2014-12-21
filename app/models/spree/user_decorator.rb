Spree.user_class.class_eval do
  has_many :user_authentications, :dependent => :destroy

  devise :omniauthable

  def apply_omniauth(omniauth)
    if email.blank?
      case omniauth['provider']
      when 'wechat'
        self.email = "#{omniauth['info']['nickname']}@mail.weixin.qq.com"
      when 'qq'
        self.email = "#{omniauth['info']['nickname']}@mail.qqconnect.qq.com"
      when 'weibo'
        self.email = "#{omniauth['info']['nickname']}@mail.weibo.com"
      else
        self.email = omniauth['info']['email'] if omniauth['info']['email'].present?
      end
    end
    user_authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (user_authentications.empty? || !password.blank?) && super
  end
end
