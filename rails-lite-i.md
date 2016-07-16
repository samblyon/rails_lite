# Rails Lite

In this project, we implement some of the basic functionality from
Rails. We will send you a zip file containing the project skeleton.

If you get stuck on something, remember to look at the documentation! Learning
to read documentation on other libraries is an incredibly important skill for
a developer.

## Phase I: Rack (Warmup)

Let's start out by building what happens when you run `rails server`.

**Rack** is a middleware that sits between a web server and a web application
framework to make writing frameworks and web servers that work with existing
software easier.
We can make a functional server with only a few lines of code from the `Rack`
module.

In order to use Rack you have to give it an `app` that it will `call` after
receiving and processing the request from the webserver. A Rack app can do very
complicated things internally (like Rails), but it can also be very simple. All
a Rack app needs to do to function properly is respond to the method `call`
receiving one argument of the request environment or `env` packaged up by Rack and then
return a properly formatted response.

An extremely simple Rack app could be:
```
Rack::Server.start(
  app: Proc.new { |env| ['200', {'Content-Type' => 'text/html'}, ['hello world']] }
)
```
This is using Rack to start a webserver and telling it that the app we are going
use is the `Proc` we are making. Since `Proc` objects respond to the `call`
method this constitutes a totally valid, if simple Rack application!

Using the `env` object and returning a properly formatted response object can be
confusing when you're doing something more complicated than just returning
`hello world`, so Rack makes available `Request` and `Response` classes that
provide a more friendly API.

In order to make our code a bit more readable we are going to create the `app`
first and then pass it into `Rack::Server#start`. Let's make a very simple app
that does that.

```
app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  res['Content-Type'] = 'text/html'
  res.write("Hello world!")
  res.finish
end
```
This is a creating an app that we could give to Rack that would simply return
the text hello world. Notice here we are creating `req` and `res` objects to
make our lives easier. Setting the `Content-Type` header tells the browser what
the server has given to it in response. We will only bother with HTML in this
project. In order to actually put things into the response body you use
`Rack::Response#write`. Finally you want to call `Rack::Response#finish` when
the `res` is done being built so Rack knows to wrap everything up for you.

In order to actually have a functioning web application we need to actually give
`app` to Rack.

```
Rack::Server.start(
  app: app,
  Port: 3000
)
```
You can specify whatever port you want here, but `3000` is a common choice.

Write the code above (both the app and the `Rack::Server#start` call) in
`bin/p01_basic_server.rb`. Try running the file, then in your browser navigate
to `http://localhost:3000`. You should see `Hello world!`. Congratulations,
you've written a Rack application.

Now we want to change our application so it doesn't only do one thing ever. We
want to respond to requests with the requested path. For example: if I type
`localhost:3000/i/love/app/academy` I want it to display `/i/love/app/academy`
in the browser.  See an example [here](http://imgur.com/IBbbzsK).

Look through the [request][rack-request] and [response][rack-response]
documentation, then change your `app` code to respond with the path requested
instead of `Hello world!`.

[rack-request]: http://www.rubydoc.info/gems/rack/Rack/Request
[rack-response]: http://www.rubydoc.info/gems/rack/Rack/Response

## Phase II: Basic ControllerBase

Consider the following code from 99cats:

```ruby
class CatsController < ApplicationController
  def index
    @cats = Cat.all
    render :index
  end
end

# ... Meanwhile, in application_controller.rb

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end


```

CatsController inherits from ApplicationController, which inherits from ActionController::Base.  Let's write a version of ActionController::Base.

We'll call the class that we're about to write `ControllerBase` instead of `ActionController::Base`, but ControllerBase will have most of the same methods. For example, we'll write the `render` and `redirect_to` methods we're used to using in our 99cats controllers.

In the `bin/p02_controller_server.rb` file, you'll see the
`MyController` class inheriting from `ControllerBase`, much like
Rails' controllers inherit from `ApplicationController` (which in turn
inherits from `ActionController::Base`). Let's get started!

We'll write our version of `ActionController::Base` in phases in the `lib`
directory of the project. `ControllerBase#initialize` should take the HTTP
Request and HTTP Response objects as inputs; it will use the request (its query
string, cookies, body content) to help fill out the response. Save the request
and response objects to instance variables (ivars) for later use.

Consider this code from 99cats:

```ruby

class CatsController < ApplicationController
  def new
    @cat = Cat.new
    
    render :new
    render :new
  end
end

```

You've probably accidentally written code like this in a project at some point.  The app probably yelled at you about a "double render" error.  We now get to write that error.

First, write a method named `render_content(content, content_type)`. This
should set the response object's `content_type` and `body`. It should
also set an instance variable, `@already_built_response`, so that it
can check that content is not rendered twice.

Next, write a method named `redirect_to(url)`. Issuing a redirect consists of
two parts, setting the 'Location' field of the response header to the redirect
url and setting the response status code to 302. Do not use #redirect; set each
piece of the response individually. Check the [Rack::Response][rack-response]
docs for how to set response header fields and statuses. Again, set
`@already_built_response` to avoid a double render.

Run `bundle exec ruby bin/p02_controller_server.rb`. Look at it to see
what it does: it tests `render_content` and `redirect_to`. Make sure
this works to your satisfaction.

Lastly, run the spec: `bundle exec rspec spec/p02_controller_spec.rb`.

**Checkpoint:** grab a TA to code review. Make sure you can walk them through line-by-line what `bin/p02_controller_server.rb` is doing.

## Phase III: Adding template rendering

### Phase IIIa: ERB and `binding`

[ERB][erb-docs], the template rendering library, is built into Ruby.

[erb-docs]: http://ruby-doc.org/stdlib-2.1.2/libdoc/erb/rdoc/ERB.html

Let's try it out:

```
[1] pry(main)> require 'erb'
=> true
[2] pry(main)> template = ERB.new('<%= (1..10).to_a.join(", ") %>')
=> #<ERB:0x007fcbcc0d5c60
 @enc=#<Encoding:UTF-8>,
 @filename=nil,
 @safe_level=nil,
 @src=
  "#coding:UTF-8\n_erbout = ''; _erbout.concat(( (1..10).to_a.join(\", \") ).to_s); _erbout.force_encoding(__ENCODING__)">
[3] pry(main)> template.result
=> "1, 2, 3, 4, 5, 6, 7, 8, 9, 10"
```

ERB will also interpolate values:

```
[5] pry(main)> x = "Hello there, world!"
=> "Hello there, world!"
[6] pry(main)> ERB.new("<%= x %>").result # raises exception
[7] pry(main)> ERB.new("<%= x %>").result(binding)
```

`binding` is a Kernel method that packages up the environment bindings
(variables, methods, and self) that are in-scope at any point of a Ruby
program and makes them available in another context. For instance:

```
[1] pry(main)> def f
[1] pry(main)*   x = 4
[1] pry(main)*   binding
[1] pry(main)* end
=> :f
[2] pry(main)> context_within_f = f()
=> #<Binding:0x007fd4ec169ae0>
[3] pry(main)> context_within_f.eval('x')
=> 4
```

Calling `f` creates a local variable, `x`, which would usually not be
visible outside of the method. However, `f` returns the result of
`Kernel#binding`, which is an instance `Binding`. The `Binding` class
has one important instance method, `#eval`, which takes in a string,
running it as Ruby code within the context that was preserved in the
`Binding` instance.

You can see that `binding` is a very special method, and we'll hardly
ever use it. However, it should make sense what it does: encapsulate all
of the in-scope variables and methods, storing them in an object, so
that the object can be passed to and used in another context.

### Phase IIIb: reading and evaluating templates

Let's write a `render(template_name)` method that will:

0. Use the controller and template names to construct the path to a
   template file.
0. Use `File.read` to read the template file.
0. Create a new ERB template from the contents.
0. Evaluate the ERB template, using `binding` to capture the
   controller's instance variables.
0. Pass the result to `render_content` with a `content_type` of
   `text/html`.

We'll assume that any developers who use our framework are aware of our
template naming convention, which is as follows:
`"views/#{controller_name}/#{template_name}.html.erb"`. Use
`ActiveSupport`'s `#underscore` (`require 'active_support/inflector'`)
method to convert the controller's class name to snake case. We'll be
lazy and not chop off the `_controller` bit at the end.

Run the `bin/p03_template_server.rb` example. Make sure it works. Then
run the `spec/p03_template_spec.rb` spec to check your work :-)

## Phase IV: Adding the Session

**Overview**:

[Cookies][cookies] are how servers store information on the client that persist
even if the user goes to a different page on the site, closes the tab, or closes
the browser. A cookie consists of a name, value, and a few other optional
attributes.

* We'll always use a single **name** for our cookie: `_rails_lite_app`.
* The **value** has to be a string, so we'll use JSON to serialize a hash
  and store that. This way we can store multiple values in the cookie.
* You can access an incoming request's cookies using the `Rack::Request#cookies`
  method, which returns a hash where the keys are cookie names and the values
  of those cookies.
* The server will only have access to a cookie with a path attribute that
  matches the current path. We want the session cookie to be accessible at any
  path, so we will have to make sure that we give the session cookie a path of
  `/`.
* Cookies are added to the client's browser by putting them into the response.
  Doing this by hand involves setting a header of `Set-Cookie`, but it's a pain
  to set the value of this header properly by hand.
* Rack gives a convenient method `Rack::Response#set_cookie` that will setup
  this header in the response properly for you if you give it the name and 
  value of the cookie to set.

**Instructions:**

You have a skeleton helper class, `Session`, in `lib/session.rb`,
which is passed an instance of `Rack::Request` on initialization.
Inside `Session#initialize` you should grab the cookie named `_rails_lite_app`.
If the cookie has been set before, you should use JSON to deserialize the value of
the cookie and store it in an ivar. If no cookie has been set before this ivar
should be set to `{}`.

Provide methods `#[]` and `#[]=` that will modify the session content;
in this way the Session is Hash-like. Finally, write a method
`store_session(response)` that will put the session into a cookie and set it 
using `Rack::Response#set_cookie`. The first argument to
`set_cookie` is the name of the cookie which should be `_rails_lite_app`.
The second argument is the cookie attributes. You specify the cookie's
attributes using a hash. You should make sure to specify the `path` and `value`
attributes. The path should be `/` so the cookie will available at
every path and the value should be the JSON serialized content of the ivar 
that contains the session data.

**NB:** In order for this to work properly, the `path` and `value` keys in your
hash must be symbols, not strings.

Implement a method `ControllerBase#session` which constructs a session from the
request. Cache this in an ivar, (`@session`;
use `||=`) that can be returned on subsequent calls to `#session`.

Make sure that the `#redirect_to` and `#render_content` methods call
`Session#store_session` so that the session information is stored in the cookie
after the response is done being built.


Test your work: 

1. Run `bin/p04_session_server.rb` and open localhost:3000.  When you first load the page, it should look like [this](http://imgur.com/8GODpwD).  
2. Now refresh.  It should look like [this](http://imgur.com/TfXGke7).  
3. Refresh again.  It should look like [this](http://imgur.com/umvJs8L).
4. Overall, the count should go up every time you refresh the page.


Once the you have the bin file working, run the `spec/p04_session_spec.rb` specfile.

**Note:** **It is not unusual if your count goes up by two for each
refresh of the page**. Browsers typically make two requests per page:
one for the page, and a second for a favicon (the icon you see in the
browser tab). If you refresh the page and notice the count increasing
by 2 each time, don't worry - it means your session hash is working.

[cookies]: http://en.wikipedia.org/wiki/HTTP_cookie

## Phase V: Routing

In this section we'll be writing a `Router` class and a `Route` class.
A `Route` object is like a single row of `rake routes`:

```
user    PUT     /users/:id      users#update
```

A `Route` object knows what path to match (`/users/:id`),
what controller it belongs to (`UsersController`) and what method to run
within that controller (`update`).

Here is the `Router`'s job in a nutshell: given an HTTP Request,
figure out which `Route` matches the requested path. Once found,
instantiate the `Route`'s controller, and run the appropriate method.

Let's get into more detail. Follow along by looking at
`bin/p05_router_server.rb`.

When our app boots up for the first time it will instantiate a
`Router`. The `Router` will have methods corresponding to the four
HTTP verbs `GET, POST, PUT, DELETE`. Notice that in the `router.draw`
block we call these methods with several arguments: a path regex, a
controller name, and a symbol that corresponds to a method name.

What each of the `get, post, put, delete` methods will do is add a
`Route` object to the `Router`'s `@routes` instance variable.

On every request `router.run` should be called with the
`Rack::Response` and `Rack::Request` as parameters. The run method will
figure out what URL was requested, match it to the path regex of one
`Route` object, and finally ask the `Route` to instantiate the
appropriate controller, and call the appropriate method.

### Phase Va: Write `Route` first

A `Router` keeps track of multiple `Route`s. Each `Route` should store
the following information:

* The URL pattern it is meant to match (`/users`, `/users/new`,
  `/users/(\d+)`, `/users/(\d+)/edit`, etc.).
* The HTTP method (GET, POST, PUT, DELETE).
* The controller class the route maps to.
* The action name that should be invoked.

Also write a method, `Route#matches?(req)`, which will test whether a `Route`
matches a request. Remember that a route is a match only if the pattern matches
the request path **and** if its `http_method` is the same as the request method
(you can use `req.request_method`). Note that `pattern` will be a `Regexp`, so
you should use the [match operator][match-operator] `=~`, not `==`.

**NB:** `Rack::Request#request_method` returns an uppercase string. `http_method`
returns a lowercase symbol. Adjust accordingly!

[match-operator]: http://ruby-doc.org/core-2.1.2/Regexp.html#method-i-3D-7E

### Phase Vb: Write the `Router`

* On `initialize`, setup an empty `@routes` ivar.
* Write a method `#add_route`, which will construct a `Route` and add
  it to the router's list.
* Define `get(pattern, controller_class, action_name)`, `post(pattern,
  controller_class, action_name`, etc. methods.
    * Each one should use `#add_route`.
    * To keep things DRY, iterate through an array of the HTTP
      methods, calling `define_method` for each.
* Write a method `Router#match` which finds the first matching route.

### Phase Vc: Invoking the action

Consider this code from a normal rails project:

```ruby

class PostsController < ApplicationController
  def new
    @post = Post.new
    
    render :new
  end
end

```

The code above defines the "new" action for the PostsController.

So when we hit the corresponding route (i.e., when we go to `localhost:3000/posts/new` in Google Chrome), the PostsController#new method will eventually run.   There's another way of saying that we want to run a method that we've defined on the controller: we want to "invoke" the "action" on the controller.

* Add a method `ControllerBase#invoke_action(action_name)`
    * use `send` to call the appropriate action (like `new` or `show`)
    * check to see if a template was rendered; if not call
      `render` in `invoke_action`.
* Add a method `Route#run(req, res)` that (1) instantiates an instance
  of the controller class and (2) calls `invoke_action`. Pass an empty
  hash as the third argument to `ControllerBase#initialize` for now.
  We'll replace that with the real route params soon.
* Add a method `Router#run(req, res)` that calls `#run` on the first
  matching route. If none is found, return a `404` error by setting the
  response status. It's also nice to add a message body so the user
  knows what went wrong.

### Phase Vd: `Router#draw`

Write a method, `Router#draw` that takes a block:

```ruby
router = Router.new
router.draw do
  get Regexp.new("^/cats$"), Cats2Controller, :index
  get Regexp.new("^/cats/(\\d+)/statuses$"), StatusesController, :index
end
```

Now wait one minute here. `post` and `get` are methods of `Router`, but
they aren't being called on the `Router` instance. Are those
methods even available in the block's context? Won't this result in a
`NameError`?

Well, yes, ordinarily it would, but we've got a nice trick up our sleeve
to get around this.

Remember our old friend `Binding#eval` from the template section? Well
she has a cousin `Object#instance_eval` who will take a proc and
evaluate it in the context of his object. Let's watch him work his
magic:

```ruby
[1] pry(main)> class Foo
[1] pry(main)*   def initialize
[1] pry(main)*     @foobar = 'foobar'
[1] pry(main)*   end
[1] pry(main)*   def bar
[1] pry(main)*     'bar'
[1] pry(main)*   end
[1] pry(main)* end
[2] pry(main)> foo = Foo.new
[3] pry(main)> blk = proc { bar }
[4] pry(main)> blk.call
NameError: undefined local variable or method 'bar' for main:Object
from (pry):10:in 'block in __pry__'
[5] pry(main)> foo.instance_eval(&blk)
=> "bar"
[6] pry(main)> foo.instance_eval { @foobar }
=> "foobar"
```

Notice that the blocks passed to `foo.instance_eval` suddenly behave as
if `self == foo`. This is *exactly* the behavior we're looking for. Now
use `#instance_eval` to implement `Router#draw`, evaluating the given
block in the router object's context.

### Phase Ve: Route params

To  simplify things, we won't support defining routes as strings like
Rails does (e.g. `"/users/:id/"`). Instead, we'll require a `Route`'s
`pattern` argument to be a `Regexp` (e.g. `Regexp.new
'/users/(?<id>\d+)'`). This is a little more complicated for other
developers to write, but Ruby will do more of the work for us by storing
any [named capture groups][named-capture-so] in a `MatchData` object.

Try the following in the ruby console:

```ruby
regex = Regexp.new '/users/(?<id>\d+)'
match_data = regex.match("/users/42")
p match_data
p match_data[:id]
```

In the above example we create an instance of `Regexp`, the regular
expression matcher class. Because we had a named capture as part of
our expression (the `(?<id>...)` part), we were able to retrieve the
value we were looking for from the resulting `match_data` at the name
we specified (`id`). If there was no match for the expression,
`match_data` would be `nil`.

In your `Route#run` method, get a `MatchData` object using the route's
`@pattern`, and then build a `route_params` hash from it. You can key
into the match data object like a hash. The keys (list them all with
`MatchData#names`) will be the names of the capture groups in your
regex, and the values will be the captures. Pass this hash to the new
controller when you initialize it.

Now in your `ControllerBase#initialize` method make sure you merge in the route
params with the query params and body params hash that `Rack::Request.params`
has parsed and packaged up for you by merging the `req.params` hash with the
`route_params`.

Great! We finally have all the params and routing in place. Run the
`bin/p05_router_server.rb` test and try requesting `/cats` and
`/cats/1/statuses`. Run the specs in `spec/p05_router_spec.rb`.

[named-capture-so]: http://stackoverflow.com/questions/18825669/how-to-do-named-capture-in-ruby

## Phase VI: Celebrate!

Run the integration spec in `spec/p06_integration_spec.rb`. Good work!
