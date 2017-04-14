class AboutController < ApplicationController
  skip_before_filter :authenticate_user!, only: [ :show, :index ]
  before_filter :set_home_page, only: [:index]

  def index; end
  def show; end

  protected

  def set_home_page
    @is_home_page = true
  end

end
