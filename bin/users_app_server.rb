begin
  require 'rack'
  require_relative '../lib/controller_base.rb'
  require_relative '../lib/router'
  require_relative '../lib/application'
  require_relative '../lib/db_connection'
  require_relative '../lib/manifest'
  require_relative '../app/controllers/UsersController'
  require_relative '../app/models/user'

  # set up the database
  DBConnection.reset

  # rake routes
  # debugger
  load File.join(Dir.pwd,'config','routes.rb')

  # build req/res app
  app = Proc.new do |env|
    req = Rack::Request.new(env)
    res = Rack::Response.new
    Application.router.run(req, res)
    res.finish
  end

  # set up middleware
  app = Rack::Builder.new do
    use ShowExceptions
    use Static
    run app
  end.to_app

  # go live!
  Rack::Server.start(
    app: app,
    port: 3000
  )

rescue
  debugger
end
