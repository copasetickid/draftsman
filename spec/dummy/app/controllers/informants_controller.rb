class InformantsController < ApplicationController

private

  def info_for_draftsman
    { :ip => '123.45.67.89', :user_agent => '007' }
  end
end
