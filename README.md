# NoBrainer CarrierWave Adapter

carrierwave-nobrainer is an adapter to make
[CarrierWave](https://github.com/carrierwaveuploader/carrierwave/) work nicely with
[NoBrainer](http://nobrainer.io).

## Installation

Include in your Gemfile:

```ruby
gem 'carrierwave', '>= 2', '< 3'
gem 'carrierwave-nobrainer'
```

Note: this adapter has only been tested with the master branch of carrierwave,
not the 0.10.0 version from Feb. 2014.

## Usage

Use carrierwave as usual.

As an added feature, you may pass `filename: 'some_filename.png' to
the `mount_uploader` method options. For example:

```ruby
mount_uploader :icon, SomeUploader, filename: 'icon.png'
```

This will have the effect of not storing this static filename in the document to
avoid polluting the DB with useless fields.

### Storing files in RethinkDB

In the case you need to store files in the RethinkDB database, this gem also
add a Carrierwave storage for NoBrainer.

To use it, in your uploader set the storage to `:nobrainer`

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :nobrainer
end
```

## License

MIT license.
