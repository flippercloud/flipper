# Flipper::Api

API for the [Flipper](https://github.com/jnunemaker/flipper) gem.

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flipper-api

## Endpoints

### Get all features

`GET /flipper-api/api/v1/features`

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

`POST /flipper-api/api/v1/features`

**Parameters**

* `name` - The name of the feature (Recommended naming conventions: lower case, snake case, underscores over dashes. Good: foo_bar, foo. Bad: FooBar, Foo Bar, foo bar, foo-bar.)

**Response**

On successful creation, the API will respond with an empty JSON response.

### Retrieve a feature

`GET /flipper-api/api/v1/features/{feature_name}`

**Parameters**

* `feature_name` - The name of the feature to retrieve

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

`DELETE /flipper-api/api/v1/features/{feature_name}`

**Parameters**

* `feature_name` - The name of the feature to delete

**Response**

Successful deletion of a feature will return a 204 No Content response.

### Enable a feature

`PUT /flipper-api/api/v1/feature/{feature_name}/enable`

**Parameters**

* `feature_name` - The name of the feature to enable

**Response**

Successful enabling of a feature will return a 204 No Content response.

### Disable a feature

`PUT /flipper-api/api/v1/feature/{feature_name}/disable`

**Parameters**

* `feature_name` - The name of the feature to disable

**Response**

Successful disabling of a feature will return a 204 No Content response.
