require 'byebug'
require 'filemagic'

class Static
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    match_data = req.path.match(/public\/(\w+\.\w+)/)

    if match_data
      res = Rack::Response.new

      file_name = match_data[1]
      file_path = public_file_path(file_name)
      file = file_at(file_path)

      if file
        res['Content-Type'] = type_of_file_at(file_path)
        res.write(file)
      else
        error = { message: "Don't have that file..."}
        res['Content-Type'] = 'text/html'
        res['Error-Type'] = error[:message]
        res.status = "404"
        res.write("#{error[:message]}")
      end

      res.finish
    else
      app.call(env)
    end
  end

  def public_file_path(file_name)
    file_path = "./public/#{file_name}"
  end

  def file_at(file_path)
    File.exist?(file_path) ? File.read(file_path) : nil
  end

  def type_of_file_at(file_path)
    FileMagic.new(FileMagic::MAGIC_MIME).file(file_path)
  end
end
