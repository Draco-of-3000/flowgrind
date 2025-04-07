class OnboardingController < ApplicationController
  before_action :authenticate_user!, except: [:welcome, :how_it_works, :account_setup]
  
  def index
    @step = params[:step] || 1
    @total_steps = 5
    
    render "onboarding/step#{@step}"
  end
  
  def welcome
    @step = 1
    @total_steps = 5
  end
  
  def how_it_works
    @step = 2
    @total_steps = 5
  end
  
  def account_setup
    @step = 3
    @total_steps = 5
  end
  
  def mode_selection
    @step = 4
    @total_steps = 5
  end
  
  def ready
    @step = 5
    @total_steps = 5
  end
end