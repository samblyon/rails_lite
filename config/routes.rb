Application.router.draw do
  #route method invocations go here
  # e.g. get REGEX ControllerName action
  get Regexp.new("^/users$"), UsersController, :index
end
