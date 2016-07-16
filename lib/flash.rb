require 'json'

class Flash
  attr_accessor :now

  def initialize(req)
    @now = {}

    serialized_cookie = req.cookies['_rails_lite_app_flash']
    if serialized_cookie
      @cookie = JSON.parse(serialized_cookie)
    else
      @cookie = {}
    end
  end

  def [](key)
    @cookie.merge(@now)[key]
  end

  def []=(key, value)
    @cookie[key] = value
  end

  def store_flash(res)
    serialized_cookie = @cookie.to_json
    res.set_cookie(
      '_rails_lite_app_flash',
      path: '/',
      value: serialized_cookie
    )
  end

end
