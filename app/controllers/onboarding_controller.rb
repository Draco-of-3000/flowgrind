class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_onboarding_status, except: [:complete]
  layout "onboarding"
  
  def welcome
    # Track current step for progress indicator
    session[:onboarding_step] = 1
  end
  
  def credits
    # Ensure user follows the sequence
    redirect_to onboarding_welcome_path unless session[:onboarding_step] >= 1
    session[:onboarding_step] = 2
  end
  
  def solo_mode
    redirect_to onboarding_credits_path unless session[:onboarding_step] >= 2
    session[:onboarding_step] = 3
  end
  
  def paired_mode
    redirect_to onboarding_solo_mode_path unless session[:onboarding_step] >= 3
    session[:onboarding_step] = 4
  end
  
  def validation
    redirect_to onboarding_paired_mode_path unless session[:onboarding_step] >= 4
    session[:onboarding_step] = 5
  end
  
  def complete
    # Only allow completion if they've gone through all steps
    redirect_to onboarding_validation_path unless session[:onboarding_step] >= 5
    
    # Mark onboarding as complete
    current_user.update(onboarding_completed: true)
    
    # Clear onboarding session data
    session.delete(:onboarding_step)
    
    # Redirect to dashboard
    redirect_to dashboard_path, notice: "Welcome to FlowGrind! You're all set to start your productivity journey."
  end
  
  private
  
  def check_onboarding_status
    # If they've already completed onboarding, redirect to dashboard
    redirect_to dashboard_path if current_user.onboarding_completed?
  end
end