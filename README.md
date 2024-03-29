# Redisant
ORM-like object storage for Redis. Makes it easy to store, find and query objects, and link them via associations.

NOTE: running the rspec tests requires that redis is running. All data in the database will be deleted.


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'redisant'
```

And then execute:

```shell
% bundle
```
Or install it yourself as:

```shell
% gem install redisant
```

## Usage
You need a Redis database use this gem. An easy way to do this is via Docker:

```shell
% docker run -d -p 6379:6379 redis
```

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing
To run the include RSpec tests, you need a Redis database for testing. ALL DATA WILL BE DELETED during testing, so be sure not to use a database with any data you want to keep. By default, the tests will try to connect to Redis on port 6387 (rather than the default 6379).

The easiest way to run a Redis database for testing is using Docker, mapping port 6379 of Redis to 6387 on the outside:

```shell
% docker run docker run -p 6387:6379 redis
``

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/emiltin/redisant. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

