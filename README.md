# Ragot

A gem to tell on methods and what they do, behind their backs. A hack to create
hooks around methods.

Either unobstrusive, with no change whatsoever in the source of the targeted
code, or with the use of Ragot inherited class methods `before` and `after`.

## Installation

Ruby 2.* (i guess).

Install it with rubygems:

    gem install ragot

With bundler, add it to your `Gemfile`:

```ruby
gem "ragot"

```

## Use

### `Ragot.about` (unobstrusive)

```ruby
irb(main):001:0> require 'ragot'
irb(main):001:0> Ragot.about String, :upcase # only to show it's easy, not to tell you it's a good idea...
irb(main):002:0> "example".upcase
`upcase` called, with params : '[]'. Got 'EXAMPLE' as result, at 2016-09-25 20:47:14 +0200 .0821934
=> "EXAMPLE"
```

`Ragot.about`can be declared anywhere in all your code base, given the targeted
class is already defined. Handy to trace a call to a gem class and method without
ripping open the library.

Targeted methods don't even need to be defined. If not already, they'll be
hooked when added to the targeted class or module.

#### Options

Let's say you have `Person` class in an `App` with a `log` method.

* block

It is executed in instance context. The return value of the targeted method,
and the arguments passed to it, are yielded to the block.

```ruby
Ragot.about Person, :save do |save_return_value, *params|
  # code executed in instance context, `full_name`, `department`, `errors` are Person instance methods
  if save_return_value
    App.log "#{full_name} created, and added to #{department} at #{Time.now}"
  else
    App.log "Problem : #{errors} when trying to create #{full_name}"
  end
end
```

* hook

Option default is `after`, but can be set to `before`.

```ruby
Ragot.about Person, :change_status, hook: :before do |new_status_param|
  App.log "#{full_name} status was #{status} before it was changed to #{new_status_param}"
end
```

* class

You want to hook a class, instead of instance, method.

```ruby
Ragot.about Person, :name, class: true do |name, *empty_params|
  App.log "#{self} class is asked its name again !"
end
```

* failsafe

You don't want to allow a hook to crash your application.

```ruby
Ragot.about Person, :cleanup_info, failsafe: true do |result, *info_to_clean|
  self.risky_external_push! info_to_clean # won't crash your app even though API call went wrong
end
```

* env

You may want to setup a hook only in a given set of environments. This option
will be compared to `Ragot.env` value, which can be set as such :

`Ragot.env = App.env`

```ruby
Ragot.about Person, :save, env: ['staging', 'production'] do |save_return_value|
  if save_return_value
    self.costy_stats_gathering! # that you don't want to do in 'development'
  end
end
```

* stamp

This will timestamp a call to a method.

```ruby
irb(main):001:0> require 'ragot'
irb(main):001:0> Ragot.about Person, :suspicious_behaviour_method, stamp: true
irb(main):002:0> Person.new.suspicious_behaviour_method
Entered to_s, with params '[]', at <this time>
Entered to_s, with params '[]', at <this other time>
Entered to_s, with params '[]', at <this yet other time>
=> "suspicious_behaviour_method_result"
```

## `before` and `after`

`before` and `after` are available as class methods when Ragot is included.

They have the same behaviour and options as `about` above (except the `hook`
option).

```ruby
class PersonAssignment
  include Ragot

  after :person= do |person, person|
    App.log "#{person.full_name} was given a new job as #{self.name}"
  end

end
```

## Thanks

Eager and sincere thanks to all the Ruby guys and chicks for making all this so
easy to devise.

## Copyright

I was tempted by the WTFPL, but i have to take time to read it.
So far see LICENSE.
