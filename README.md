# Rails Lite (& ActiveRecord Lite)
Hand-rolled implementation of the basic functionality of Ruby on Rails and Active Record, to improve my understanding of how these tools work under the hood.

### Rails functionality built:
* Singleton `Router` with REGEX based route generation
* `ApplicationController` (as `ControllerBase`)
* Rendering of `erb` template views
* `Session`, `Flash` and `Flash.now`
* CSRF protection with `form authenticity token` helper
* Basic `middleware` (`StaticAssets` & `ShowExceptions`)

### Active Record functionality built:
* `ActiveRecord::Base` model superclass (as `SQLObject`)
  * `find`, `all`, `create`, `update`, `destroy`
  * chainable `where` and `where_lazy`
* `ActiveRecord::Relation` (as `Relation`)
* Support for `belongs_to`, `has_many` and `has_one_through` associations

### Future additions
* Conversion to a gem
* Additional ORM functionality:
  * Chainable, lazy `join`s
  * Eager loading with `includes`
  * Polymorphic associations
