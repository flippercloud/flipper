# Flipper Http

HTTP adapter for use with the [Flipper Api](https://github.com/jnunemaker/flipper/blob/master/docs/api/README.md).

Given you have [mounted](https://github.com/jnunemaker/flipper/blob/master/docs/api/README.md#user-content-usage) the Flipper Api on an application, you can use the HTTP adapter to interact with Flipper just like any other adapter, and internally it will handle all the http requests for you.  This means that you can have the application exposing the API store your Flipper data, but interact with it from other Ruby apps.

Initialize the HTTP adapter with a configuration Hash.
```ruby
require 'flipper/adapters/http'

configuration = {
  uri: URI('http://app.com/mount-point'), # required
  headers: { 'X-Custom-Header' => 'foo' },
  basic_auth_username: 'user123',
  basic_auth_password: 'password123'
  read_timeout: 75,
  open_timeout: 70
}

adapter = Flipper::Adapters::Http.new(configuration)
flipper = Flipper.new(adapter)
```

**Required keys**:
* uri: [URI](https://docs.ruby-lang.org/en/2.3.0/URI.html) object referencing url where [Flipper Api](https://github.com/jnunemaker/flipper/blob/master/docs/api/README.md) is mounted.

**Optional keys**:
*These will affect every request the adapter makes.  For example, send basic auth credentials with every request.*

* headers: HTTP headers.
* basic_auth_username:  Basic Auth username.
* basic_auth_password: Basic Auth password.
* read_timeout: [number in seconds](https://docs.ruby-lang.org/en/2.3.0/Net/HTTP.html#attribute-i-read_timeout).
* open_timeout: [number in seconds](https://docs.ruby-lang.org/en/2.3.0/Net/HTTP.html#attribute-i-open_timeout).
