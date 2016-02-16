# Alephant::Storage

Simple abstraction layer over S3 for get/put.

[![Build
Status](https://travis-ci.org/BBC-News/alephant-storage.png)](https://travis-ci.org/BBC-News/alephant-storage)

[![Gem Version](https://badge.fury.io/rb/alephant-storage.png)](http://badge.fury.io/rb/alephant-storage)

## Installation

Add this line to your application's Gemfile:

    gem 'alephant-storage'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alephant-storage

## Usage

```rb
require 'alephant/storage'

storage = Alephant::Storage.new('bucket_id', 'base/path')
storage.put('id', "string data")
storage.get('id')

# => "string data"
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/alephant-storage/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
