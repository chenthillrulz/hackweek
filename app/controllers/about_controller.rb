class AboutController < ApplicationController
  skip_before_filter :authenticate_user!, only: [ :show, :index, :credits ]
  before_filter :set_home_page, only: [:index]

  def index; end
  def show; end
  def credits; end

  protected

  def set_home_page
    @is_home_page = true
  end

end
