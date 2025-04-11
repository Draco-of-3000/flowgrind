class Users::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(resource)
    # Check if the user has completed onboarding
    if resource.onboarding_completed?
      dashboard_path
    else
      onboarding_welcome_path
    end
  end
end