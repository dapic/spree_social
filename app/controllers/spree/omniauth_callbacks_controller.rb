class Spree::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Store
  #  skip_before_filter :verify_authenticity_token

  def self.provides_callback_for(*providers)
    providers.each do |provider|
      class_eval <<-FUNCTION_DEFS, __FILE__, __LINE__ + 1
        def #{provider}
          if request.env['omniauth.error'].present?
            flash[:error] = I18n.t('devise.omniauth_callbacks.failure', kind: auth_hash['provider'], reason: Spree.t(:user_was_not_valid))
            redirect_back_or_default(root_url)
            return
          end

          authentication = Spree::UserAuthentication.find_by_provider_and_uid(auth_hash['provider'], auth_hash['uid'])
          # 如果是已经用此联合登录账户登录过的用户
          if authentication.present? and authentication.try(:user).present?
            # user_login = authentication.user.user_logins.find_or_create_by(login_type: 3, login: "#\{auth_hash['uid']}@#\{auth_hash['provider']\}")
            # user_login.register
            authentication.user.update_login(auth_hash)
            flash[:notice] = I18n.t('devise.omniauth_callbacks.success', kind: auth_hash['provider'])
            store_location_for(:spree_user, oauth_connect_url) unless authentication.user.phone
            sign_in_and_redirect :spree_user, authentication.user
          # 已有一个登录了的spree账户，现在用omniauth登录，则关联这两个账户。这种情况目前（2015-10-31）其实不存在。
          elsif spree_current_user
            spree_current_user.apply_omniauth(auth_hash)
            spree_current_user.save!
            user_login = spree_current_user.user_logins.find_or_create_by(login_type: 3, login: "#\{auth_hash['uid']}@#\{auth_hash['provider']\}")
            user_login.register
            flash[:notice] = I18n.t('devise.sessions.signed_in')
            redirect_back_or_default(account_url)
          else # 第一次用联合登录账户登录，则创建新的Spree账户
            user = ( Spree::User.find_by_email(auth_hash['info']['email']) if auth_hash['info']['email'] ) || Spree::User.new
            user.apply_omniauth(auth_hash)
            if user.save
              user_login = user.user_logins.create(login_type: 3, login: "#\{auth_hash['uid']}@#\{auth_hash['provider']\}")
              user_login.register
              # flash[:notice] = I18n.t('devise.omniauth_callbacks.success', kind: auth_hash['provider'])
              store_location_for(:spree_user, oauth_connect_url)
              sign_in_and_redirect :spree_user, user
            else
              puts "could ot save user #\{user.errors\}"
              session[:omniauth] = auth_hash.except('extra')
              flash[:notice] = Spree.t(:one_more_step, kind: auth_hash['provider'].capitalize)
              redirect_to new_spree_user_registration_url
              return
            end
          end

          if current_order
            user = spree_current_user || authentication.user
            current_order.associate_user!(user)
            session[:guest_token] = nil
          end
        end
      FUNCTION_DEFS
    end
  end

  SpreeSocial::OAUTH_PROVIDERS.each do |provider|
    provides_callback_for provider[1].to_sym
  end

  def failure
    set_flash_message :alert, :failure, kind: failed_strategy.name.to_s.humanize, reason: failure_message
    redirect_to spree.login_path
  end

  def passthru
    render file: "#{Rails.root}/public/404", formats: [:html], status: 404, layout: false
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
