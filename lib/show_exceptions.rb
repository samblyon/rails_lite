require 'erb'
require 'byebug'

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    app.call(env)
  rescue Exception => e
    render_exception(e)
  end

  private

  def render_exception(error)
    response = Rack::Response.new

    response.status = "500"
    response['Content-Type'] = 'text/html'
    response['Error-Type'] = error.message

    file_name = "lib/templates/rescue.html.erb"
    template = ERB.new(File.read(file_name))
    html = template.result(binding)

    response.write(html)

    response.finish
  end

end
