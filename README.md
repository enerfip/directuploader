# DirectUploader

The goal of this gem is to make direct upload to S3 with Ruby On Rails/ActiveRecord easy as a pie. The initial goal is not
to have a multi-framework, multi-orm, multi-provider solution, but to fit only with this very specific (while very mainstream) configuration.

## Dependencies

* Ruby On Rails (v4/5)
* jQuery
* jQuery File Upload
* ActiveRecord
* Fog::Aws

This gem adds the following:

* a `direct_uploader` class method to `ActiveRecord`
* a `directupload_field_for` view helper to add a direct upload field
* a (quite) small Javascript that relies on [jquery.fileupload](https://github.com/blueimp/jQuery-File-Upload)
* That's it ... for the moment :)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'direct_uploader'
```

And then execute:

    $ bundle

### Installing external dependency : jquery.fileupload

You must take this external dependency installation on your own. Either use npm, Webpacker.. whatever and then include it in your project JS

```
#= require jquery-file-upload
#= require jquery-file-upload/js/jquery.fileupload-process
#= require jquery-file-upload/js/jquery.fileupload-validate
```

## Usage

Include `DirectUploader::Model` module and add `direct_uploader` directive to your model, as well as the *required* `upload_path` and the *optional* `document_filename`:

```ruby
class User < ApplicationRecord
  include DirectUploader::Model
  direct_uploader :avatar

  def upload_path
    "/some-path/"
  end
end
```

## Testing
While `direct_uploader`'s purpose is only to manage files on a S3 Storage, it ships with a basic file adapter so your tests do not call any external service.
Add this somewhere in your tests support files :

```
Rails.configuration.define_singleton_method(:direct_uploader_adapter) { DirectUploader::Adapter::FileSystem }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/enerfip-dev/directuploader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Directuploader project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/enerfip-dev/directuploader/blob/master/CODE_OF_CONDUCT.md).
