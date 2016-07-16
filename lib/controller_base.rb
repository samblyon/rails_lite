require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def self.protect_from_forgery
    #code
  end

  # Setup the controller
  def initialize(req, res, route_params={})
    @req = req
    @res = res
    @already_built_response = false
    @params = @req.params.merge(route_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  def response_is_built
    @already_built_response = true
  end

  def confirm_first_response
    raise if already_built_response?
  end

  # Set the response status code and header
  def redirect_to(url)
    confirm_first_response
    @res.status = 302
    @res['Location'] = url
    session.store_session(@res)
    flash.store_flash(@res)
    response_is_built
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    confirm_first_response
    @res.write(content)
    @res['Content-Type'] = content_type
    session.store_session(@res)
    flash.store_flash(@res)
    response_is_built
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    file_name = File.dirname(__FILE__)[0..-5] + "/app/views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    template = ERB.new(File.read(file_name))
    html = template.result(binding)
    render_content(html, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  def form_authenticity_token
    @token ||= SecureRandom::urlsafe_base64
    @res.set_cookie('authenticity_token', path: '/', value: @token)
    @token
  end

  def check_authenticity_token
    provided_token = @params["authenticity_token"]
    cookie_token = @req.cookies['authenticity_token']
    if provided_token.nil? || cookie_token != provided_token
      raise "Invalid authenticity token"
    end
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    if !@req.get?
      check_authenticity_token
    end
    self.send(name)
    unless already_built_response?
      render(name)
    end
  end
end
