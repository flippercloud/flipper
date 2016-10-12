# Flipper::Api

API for the [Flipper](https://github.com/jnunemaker/flipper) gem.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flipper-api

## Usage

`Flipper::Api` is a mountable application that can be included in your Rails/Ruby apps. In a Rails application, you can mount `Flipper::Api` to a route of your choice:

```ruby
# config/routes.rb
YourRailsApp::Application.routes.draw do
  mount Flipper::Api.app(flipper) => '/flipper-api'
end
```

For more advanced mounting techniques and for suggestions on how to mount in a non-Rails application, it is recommend that you review the [`Flipper::UI` usage documentation](https://github.com/jnunemaker/flipper/blob/master/docs/ui/README.md#usage) as the same approaches apply to `Flipper::Api`.

## Endpoints

**Note:** Example CURL requests below assume a mount point of `/flipper-api`.

### Get all features

**URL**

`GET /api/v1/features`

**Request**

```
curl http://example.com/flipper-api/api/v1/features
```

**Response**

Returns an array of feature objects:

```json
{
  "features": [
    {
      "key": "search",
      "state": "on",
      "gates": [
        {
          "key": "boolean",
          "name": "boolean",
          "value": false
        },
        {
          "key": "groups",
          "name": "group",
          "value": []
        },
        {
          "key": "actors",
          "name": "actor",
          "value": []
        },
        {
          "key": "percentage_of_actors",
          "name": "percentage_of_actors",
          "value": 0
        },
        {
          "key": "percentage_of_time",
          "name": "percentage_of_time",
          "value": 0
        }
      ]
    },
    {
      "key": "history",
      "state": "off",
      "gates": [
        {
          "key": "boolean",
          "name": "boolean",
          "value": false
        },
        {
          "key": "groups",
          "name": "group",
          "value": []
        },
        {
          "key": "actors",
          "name": "actor",
          "value": []
        },
        {
          "key": "percentage_of_actors",
          "name": "percentage_of_actors",
          "value": 0
        },
        {
          "key": "percentage_of_time",
          "name": "percentage_of_time",
          "value": 0
        }
      ]
    }
  ]
}
```

### Create a new feature

**URL**

`POST /api/v1/features`

**Parameters**

* `name` - The name of the feature (Recommended naming conventions: lower case, snake case, underscores over dashes. Good: foo_bar, foo. Bad: FooBar, Foo Bar, foo bar, foo-bar.)

**Request**

```
curl -X POST -d "name=reports" http://example.com/flipper-api/api/v1/features
```

**Response**

On successful creation, the API will respond with an empty JSON response.

### Retrieve a feature

**URL**

`GET /api/v1/features/{feature_name}`

**Parameters**

* `feature_name` - The name of the feature to retrieve

**Request**

```
curl http://example.com/flipper-api/api/v1/features/reports
```

**Response**

Returns an individual feature object:

```json
{
  "key": "search",
  "state": "off",
  "gates": [
    {
      "key": "boolean",
      "name": "boolean",
      "value": false
    },
    {
      "key": "groups",
      "name": "group",
      "value": []
    },
    {
      "key": "actors",
      "name": "actor",
      "value": []
    },
    {
      "key": "percentage_of_actors",
      "name": "percentage_of_actors",
      "value": 0
    },
    {
      "key": "percentage_of_time",
      "name": "percentage_of_time",
      "value": 0
    }
  ]
}
```

### Delete a feature

**URL**

`DELETE /api/v1/features/{feature_name}`

**Parameters**

* `feature_name` - The name of the feature to delete

**Request**

```
curl -X DELETE http://example.com/flipper-api/api/v1/features/reports
```

**Response**

Successful deletion of a feature will return a 204 No Content response.

### Enable a feature

**URL**

`PUT /api/v1/feature/{feature_name}/enable`

**Parameters**

* `feature_name` - The name of the feature to enable

**Request**

```
curl -X PUT http://example.com/flipper-api/api/v1/features/reports/enable
```

**Response**

Successful enabling of a feature will return a 204 No Content response.

### Disable a feature

**URL**

`PUT /api/v1/feature/{feature_name}/disable`

**Parameters**

* `feature_name` - The name of the feature to disable

**Request**

```
curl -X PUT http://example.com/flipper-api/api/v1/features/reports/disable
```

**Response**

Successful disabling of a feature will return a 204 No Content response.
