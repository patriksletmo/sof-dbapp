class API::V1::FunkisController < ApplicationController
  def index
    render :json => FunkisCategory.all, include: [:funkis_shift]
  end

  def create
    raise 'Not implemented'
  end

  def show
    raise 'Not implemented'
  end

  def update
    raise 'Not implemented'
  end

  def delete
    raise 'Not implemented'
  end
end
