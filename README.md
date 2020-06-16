# ArtEry - Client Development > Cloud Deployment

ArtEry conceptually allows you to develop, test and debug applications 100% as client-code, but with the security and performance of cloud-code. When you deploy to production, it's trivial to control which code goes in the Client, Server or Both.

* developing, testing and maintaining server-side code is 10x harder than client-side code
* so... don't write a single line of server-side code

## Why ArtEry?

The basic idea of ArtEry is to develop your entire app in one runtime, client-side. Then, for production, ArtEry manages deploying some of your code to the cloud and some to the client-app. ArtEry gives you full control over what code runs cloud-side, client-side or both.

Benefits:

* Fastest possible development (testing, debugging, build cycle)
* Security
* Performance
* Eliminate code duplication
* Together with ArtEryServer, generate a full REST API automatically

### Fastest Possible Development

Client-code has many advantages over cloud-code:

* easier to test
* easier to debug
* dramatically shorter build cycle

In short, it's *much* faster to develop.

The key observation is code is easier to develop, test and debug when it's **all in one runtime**. Stack traces span your full stack. You can hot-reload your full stack for rapid development.

### Security and Performance

There are some things that can't be done safely client-side:

* Authentication
* Authorization
* Validation
* TimeStamps
* Update Counts

Pipeline filters make it easy to apply any security rules you need.

### Performance

Some requests are more efficient to process in the cloud:

* requests with require multiple cloud-side requests
  * client-to-cloud requests typically cost much more than cloud-to-cloud request
* requests which consume a bunch of data, reduce it, and output much less data
  * cloud-to-client data-transfer typically costs much more than cloud-to-cloud
* requests with a lot of computation

Adding custom handler-types for complex requests make this easy to do. A robust "sub-request" system makes synthesizing complex requests easy in a scalable, performant way.

### Eliminate Code Duplication

Some code should run both on the cloud and client. Specifically, validation should happen client-side for the fastest possible response to client actions, /but it needs to be verified in the cloud for security. ArtEry makes it trivial to re-use code across your full stack.

## Example

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

## How it Works

* Declare one or more `pipelines` with `handlers` and `filters`
* Make client-side `requests` to those pipelines
* The pipeline takes care of routing the request wherever it needs to go.

All requests are handled with promises in a (nearly) pure-functional way. Each filter and handler returns a NEW request or response, passing the information down the pipeline. Since each step of the pipeline is handled as a promise, you can get maximum scalable performance out of node.js.

### Pipelines

Pipelines are the main structural unit for ArtEry. A pipeline consists of:

* name: <String> - derived from the pipeline's class-name
* handlers: a map from request-types to handlers: `[<String>]: <Handler>`
* filters:

A pipeline is a named grouping of request-types and filters. When designing an API for a database-backed backend, it's usually best to have one pipeline per table in your database.

### Handlers

Handlers are just functions:

```
(<Request>) -> <[optional Promise] Response, null, plain-Object, or other response-compatible-data-types>
```

### Requests and Responses

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

### Filters

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

  @before create: (request) -> ...
  @after  create: (request) -> ...
```

## FAQ

* Should I put my request-fields in `request.props` or `request.data`?

  * NOTE: `request.data == request.props.data` - in other words, data is actually a props-field with a convenient accessor.
  * You can put anything in props.data and almost anything in props itself.
  * Recommendation: If the field is one of the defined @fields, it goes in data. Else, put it in props.
  * Why? To make filters as re-usable as possible, they need to make assumptions about your request-props and response-props.

* What do you mean by "Nearly" pure-functional?

  * To facilitate more complex sub-request patterns, each root-request has a mutable `context` object for shared state across all sub-requests. This is useful for functionality such as caching sub-requests. Keeping all context attached to the root request rather than somewhere else ensures we can have any number of request in flight simultaneously. In general, only advanced filter-developers should touch the context object. Almost everything you'll ever need to do can be done in a pure-functional way with normal filters and handlers.

# TODO

Use the `Authorization: Bearer` HTTP header to pass a session on `GET` requests. https://stackoverflow.com/questions/33265812/best-http-authorization-header-type-for-jwt