## ArtEry - 100% Client-Side Cloud-Code Development

ArtEry conceptually allows you to write apps 100% as client-code, but with the security and performance of cloud-code. It is a pipelined business-logic framework for cloud-backed data.

* developing, testing and maintaining server-side code is 10x harder than client-side code
* so... don't write a single line of server-side code

#### Client Development > Cloud Deployment

The basic idea of ArtEry is to develop your business-logic client-side with either a dumb-local or dumb-cloud backend. Then, for production, let the framework manage deploying some of your code to the cloud and some to the client-app as needed. The framework gives you full control over what code runs cloud-side, client-side or on both.

Benefits:

* Fastest possible development (testing, debugging, build cycle)
* Cloud-side security and performance
* Elliminate code duplication

#### Why Client Code?

Client-code has many advantages over cloud-code:

* easier to test
* easier to debug
* dramatically shorter build cycle
* In short, it's *much* faster to develop.

#### Why Cloud Code?

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

#### Validations and Code Duplication

Some code should run both on the cloud and client. Specifically, validation should happen client-side for the fastest possible response to client actions, but it needs to be verified in the cloud for security.

### Custom Pipeline Example

```coffeescript
# CaffeineScript
class Post extends &ArtEry.KeyFieldsMixin &ArtEry.Pipeline
  @addDatabaseFilters
    text: :trimmedString

  constructor: ->
    super
    @data = {}

  @handlers
    get: ({key}) -> 
      @data[key]
    
    create: ({data}) -> 
      @data[key] = merge data, id: key = randomString()
      
    update: ({key, data}) -> 
      @data[key] = merge @data[key], data
```

Use:

```coffeescript
{post} = &ArtEry.pipelines

post.create data: text: "Hello world!"
.then ({id})->
  post.get key: id
.then ({text}) ->
  console.log text  # Hello world!
```