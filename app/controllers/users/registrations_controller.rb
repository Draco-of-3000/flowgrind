class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  
  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :first_name, :last_name, :timezone])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :first_name, :last_name, :timezone])
  end
  
  
  def after_sign_up_path_for(resource)
    onboarding_welcome_path
  end
  
  def after_inactive_sign_up_path_for(resource)
    # If using confirmable and the user needs to confirm their email first
    new_user_session_path
  end
end