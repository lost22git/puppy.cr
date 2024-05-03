# puppy

[API DOC](https://lost22git.github.io/puppy.cr)

Http Client based on platform http api.

Inspire from [puppy nim](https://github.com/treeform/puppy)

## Status

- [x] Windows
- [ ] Linux 
- [ ] Macos

## Feature

- No openssl required (aka. you can `crystal build -Dwithout_openssl`)
- Http proxy support


## Limit

- No support response body streaming
- More to be discover

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     puppy:
       github: lost22git/puppy.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "puppy"

response = Puppy.get "https://httpbin.org/status/444"

puts response.body_io.gets_to_end
```


## Development

### Run tests

```sh
crystal spec --progress
```

## Contributing

1. Fork it (<https://github.com/lost22git/puppy.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lost](https://github.com/lost22git) - creator and maintainer
