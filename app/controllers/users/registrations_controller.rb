class Users::RegistrationsController < Devise::RegistrationsController
  protected
  
  def after_sign_up_path_for(resource)
    onboarding_welcome_path
  end
  
  def after_inactive_sign_up_path_for(resource)
    # If using confirmable and the user needs to confirm their email first
    new_user_session_path
  end
end