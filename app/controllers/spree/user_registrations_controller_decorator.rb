Spree::UserRegistrationsController.class_eval do
  after_action :clear_omniauth, only: :create
  before_action :check_registration, only: [:oauth_connect, :oauth_binding]

  # refs #328
  # 用于联合登录后，绑定手机号并填写密码
  def oauth_connect
    self.resource = spree_current_user
  end

  def oauth_binding
    self.resource = resource_class.confirm_by_sms_token(params[:sms_token])
    # self.resource = resource_class.find 1003
    # self.resource = spree_current_user
    if resource.errors.empty?
      resource.user_logins.find_by( login: params[:spree_user][:phone] ).confirm
      if resource.reset_password!(params[:spree_user][:password], params[:spree_user][:password_confirmation])
        set_flash_message(:notice, :oauth_connect_success)
        # sign_in(:spree_user, resource)
        # associate_user
        # respond_with resource, location: after_sign_up_path_for(resource)
        # sign_up(:spree_user, resource)
        store_location_for(:spree_user,cookies["return_url"])
        sign_in_and_redirect :spree_user, resource, event: :authentication, bypass: true

      end
    else
      clean_up_passwords(resource)
      redirect_to :back
    end
  end

  private

  def build_resource(*args)
    super
    @spree_user.apply_omniauth(session[:omniauth]) if session[:omniauth]
    @spree_user
  end

  def clear_omniauth
    session[:omniauth] = nil unless @spree_user.new_record?
  end

  def check_registration
    redirect_to spree_login_path unless try_spree_current_user
  end
end
