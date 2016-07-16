require_relative '../../lib/controller_base'
require_relative '../models/user.rb'

class UsersController < ControllerBase
  def index
    @users = User.all
  end
end
