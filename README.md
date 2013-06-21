# Signet::Rails

A basic Rails wrapper around the [Signet](https://github.com/google/signet) gem that handles persistence of a user's credentials on top of handling the auth flow within Rails applications. Check out [an example Rails app](https://github.com/myitcv/test-signet-rails) that utilises this gem.

Please note this is very much work in progress... issues/suggestions/etc gratefully received. Raise an issue/create a pull-request.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'signet-rails'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install signet-rails
```

## Usage

Check out [an example Rails app](https://github.com/myitcv/test-signet-rails) that utilises this gem.

## TODO

A list of items still todo or work in progress

0. Give an example usage
 * Example of setting default options
 * Example of setting per provider options
 * Clearly document default `extract\_from\_env`
 * Clearly document default `extract\_by\_oauth\_id`
1. Is there a better (Rails) way to creating per-request instances of signet OAuth clients?
2. Currently use the env variable to store the handlers and references to the instances... is this thread safe (probably) and the best way (probably not)?
3. Better way of sourcing the Google default authorization_uri and token_credential_uri? From signet directly?
4. Clear definition of the Signet options and the `signet-rails` options
5. More Rails-esque way of getting the `rack.session` in `extract\_from\_env`?
6. Better way of loading persistence wrappers in builder?
7. Check to see whether we have all required signet options at the end of Builder.provder?
8. Sort out `approval\_prompt` vs 'prompt'
9. Better `auth\_options` split at the end of Builder.provider?
10. Avoid having to dup options the whole time: fix signet?
11. Refactor Handler.handle code... messy
12. Document handling of callback in Rails
13. Error handling...
14. Document the various `env` values that can/will be set and when (e.g. `signet.XXX.persistence\_obj` on `auth\_callback`)
15. Allow shortened form of common scopes (userprofile etc)
16. Provider `application_name` and `applicatio_version` when initialising the client (per signet error)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
