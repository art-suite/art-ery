## ArtEry - 100% Client-Side Cloud-Code Development

ArtEry conceptually allows you to write apps 100% as client-code, but with the security and performance of cloud-code. It is a pipelined business-logic framework for cloud-backed data.

* developing, testing and maintaining server-side code is 10x harder than client-side code
* so... don't write a single line of server-side code

#### Client Development > Cloud Deployment

The basic idea of ArtEry is to develop your business-logic client-side with either a dumb-local or dumb-cloud back-end. Then, for production, let the framework manage deploying some of your code to the cloud and some to the client-app, as needed. The framework gives you full control over what code runs cloud-side, client-side or on both.

Benefits:

* Fastest possible development (testing, debugging, build cycle)
* Security and performance
* Eliminate code duplication

#### Fastest Possible Development

Client-code has many advantages over cloud-code:

* easier to test
* easier to debug
* dramatically shorter build cycle

In short, it's *much* faster to develop.

The key observation is code is easier to develop, test and debug when it's **all in one runtime**. Stack traces span your full stack. You can hot-reload your full stack for rapid development.

#### Security and Performance

But, there are some things that can't be done safely client-side:

* Authentication
* Authorization
* Validation
* TimeStamps
* Update Counts

And some requests are more efficient to process in the cloud:

* requests with require multiple cloud-side requests
  * client-to-cloud requests typically cost much more than cloud-to-cloud request
* requests which consume a bunch of data, reduce it, and output much less data
  * cloud-to-client data-transfer typically costs much more than cloud-to-cloud
* requests with a lot of computation

#### Eliminate Code Duplication

Some code should run both on the cloud and client. Specifically, validation should happen client-side for the fastest possible response to client actions, /but it needs to be verified in the cloud for security. ArtEry makes it trivial to re-use code across your full stack.

### Custom Pipeline Example

```coffeescript
# language: CaffeineScript
import &ArtEry

# simple in-memory CRUD data-store
class Post extends Pipeline

  constructor: -> @data = {}

  # crud-api
  @handlers
    get:    ({key})       -> @data[key]
    create: ({data})      -> @data[key] = merge data, id: key = randomString()
    update: ({key, data}) -> @data[key] = merge @data[key], data
    delete: ({key})       -> delete @data[key]

  # text-trimming filter
  @before
    update: trimText = (request) -> request.withMergedData text: request.data.text?.trim()
    create: trimText
```

Use:

```coffeescript
pipelines.post.create data: text: "Hello world!"
.then ({id})   -> pipelines.post.get id
.then ({text}) -> console.log text  # Hello world!
```

### Concepts

#### Pipelines

Pipelines are the main structural unit for ArtEry. A pipeline consists of:

* name: <String> - derived from the pipeline's class-name
* handlers: a map from request-types to handlers: `[<String>]: <Handler>`
* filters:

A pipeline is a named grouping of request-types and filters. When designing an API for a database-backed backend, it's usually best to have one pipeline per table in your database.

#### Handlers

Handlers are just functions:

```
(<Request>) -> <[optional Promise] Response, null, plain-Object, or other response-compatible-data-types>
```

#### Requests and Responses

At their most simple, requests and responses both look like this:

```
type: <String>
props:
  key:  <any, but usually String>
  data: <any, but usually Object>
  <any, but usually nothing>
```

For convenience, there are some common getters:

```
# getters
key:  -> @props.key
data: -> @props.data
```

#### Filters

At their simplest, functions are almost exactly the same as handlers:

```
# before-handler
(<Request>) -> <[optional Promise] Request, Response, plain-Object, or other response-compatible-data-types>

# after-handler
(<Response>) -> <[optional Promise] Response, plain-Object, or other response-compatible-data-types>
```

In general, each filter applies to the whole pipeline. It can filter any before and after any request-type. In practice, you'll write filters which only filter certain request-types and perhaps only before or after the handler.

Filters can also be configured to run client-side, server-side or both:

```coffeescript
class MyFilter extends Filter

  @location :client # :server or :both

  @before
    create: (request) -> ...

  @after
    create: (request) -> ...
```

### FAQ

* Should I put my request-fields in `request.props` or `request.data`?

  * NOTE: `request.data == request.props.data` - in other words, data is actually a props-field with a convenient accessor.
  * You can put anything in props.data and almost anything in props itself.
  * Recommendation: If the field is one of the defined @fields, it goes in data. Else, put it in props.
  * Why? To make filters as re-usable as possible, they need to make assumptions about your request-props and response-props.
