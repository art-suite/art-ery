## ArtEry

A pipelined business-logic framework for cloud-backed data.

ArtEry conceptially allows you to write apps with 100% client code.

#### Why Client Code?

Client-code has many advantages over cloud-code:

* easier to test
* easier to debug
* dramatically shorter code-compile-run development cycle
* In short, it's *much* faster to develop.

#### Why Cloud Code?

But, there are somethings that can't be done safely client-side:

* Authentication
* Authorization
* Validation

Some things are more efficiently done in the cloud:

* Client-side requests which require multiple cloud-side requests
  * client-to-cloud requests typically cost much more than cloud-to-cloud request
* Requests which consume a bunch of data, reduce it, and output much less data
  * cloud-to-client data-transfer typically costs much more than cloud-to-cloud

#### Client Development > Cloud Deployment

The basic idea of ArtEry is to develop your business-logic client-side with either a dumb local or cloud backend. Then, for production, the framework deploys your code and places some of it in the cloud for security and performance and keeps some of it client-side.