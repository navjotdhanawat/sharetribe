class LandingController < ApplicationController
  layout "application"

  def index
    @skip_app_styles = true 
    @no_top_search = true
  end
end
