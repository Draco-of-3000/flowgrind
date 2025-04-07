class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :check_onboarding
  
  def index
    # Dashboard content will go here
  end
  
  private
  
  def check_onboarding
    # Redirect to onboarding if user hasn't completed it
    redirect_to onboarding_welcome_path unless current_user.onboarding_completed?
  end
end
