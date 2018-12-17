Foundation = require 'art-foundation'
Request = require './Request'
Response = require './Response'
{config} = require './Config'

{toPlainObjects, Validator, toInspectedObjects, getInspectedObjects, defineModule, BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone, CommunicationStatus} = Foundation
{success} = CommunicationStatus
{normalizeFields} = Validator

###
TODO

Filters should be able to detect if they are being run server-side or client-side.
  This is a simple global value, since the entire code-base is either running in Node or in the Browser.
  It doesn't change at runtime - duh!
  So, I think we should have a value like: Art.Ery.location, which is set at init-time
  to the code-base's running location.

  WHY do we need this? Filters may want to run on both AND run a little differently on both.

    LinkFieldsFilter, for example, would translate a linked field {foo: id: 123} to {fooId: 123} and not need
    to transmit the whole foo-record over the wire. BUT, if the data was {foo: username: "hi"}, that indicates
    a new foo-record should be created, and that should be done server-side.

    IT's a little thing right now, so I'm not implementing it... yet

  WHY PART 2

    This may be the solution to Filters which are not symmetrical. It's possible the before-part should be
    client-side-only, but the after-part should be server-side-only (for example).

    We could add @beforeLocation and @afterLocation props, but maybe this one solution is "good enough" for everything.
    The only down-side is it isn't as clear in the ArtEry-Pipeline report, but that may be OK since it doesn't seem like
    it'll be used that much.

Art.Ery.location values:
  "server"
  "client"
  "both" - this is the "serverless" mode, it's all run client-side, but it includes both client-side and server-side filters.

SBD:
  location: 'client' filters WILL run server-side for server-initiated requests.
  Maybe 'client' should be 'requester' instead of 'client'? 'requester' and 'server'?
###

defineModule module, class Filter extends require './RequestHandler'

  ############################
  # Class Declaration API
  ############################
  @extendableProperty
    ###
    @after: foo: (request) ->
      IN: Request instance
      OUT: return a Promise returning one of the list below OR just return one of the list below:
        Request instance
        Response instance
        anythingElse -> toResponse anythingElse

      To reject a request:
      - throw an error
      - return a rejected promise
      - or create a Response object with the appropriate fields
    ###
    before: {}

    ###
    @before: foo: (response) ->
      IN: Request instance
      OUT: return a Promise returning one of the list below OR just return one of the list below:
        Request instance
        Response instance
        anythingElse -> toResponse anythingElse

      To reject a request:
      - throw an error
      - return a rejected promise
      - or create a Response object with the appropriate fields

    ###
    after: {}

  ###
  fields
  ###
  @extendableProperty
    fields: {}
  , extend: (oldFields, addFields) ->
    merge oldFields, normalizeFields addFields

  # If true, any after-filters will process both successful AND failed responses
  # By defailt, after-filters will only filter successful responses.
  @extendableProperty filterFailures: false

  ###
  location: determine if the filter will run on the 'server', 'client' or 'both'.
  ###
  @locationNames: locationNames =
    server: true
    client: true
    both: true

  @extendableProperty
    location: "server"
  , extend: (__, v) ->
    throw new Error "invalid location: #{v}" unless locationNames[v]
    v

  ###
  Filter Groups: default: "middle"

  Filter sequence, based on groups:
    loggers beforeFilter
      outer beforeFilter
        middle beforeFilter
          inner beforeFilter
            handler
          inner afterFilter
        middle afterFilter
      outer afterFilter
    loggers afterFilter

  ###
  @groupNames:
    loggers: 2
    outer:  1
    outter: 1 # depricated, damn spelling!
    middle: 0
    inner:  -1

  @extendableProperty
    group: @groupNames.middle
  , extend: (__, v) ->
    if v?
      throw new Error "invalid Filter group: #{v}" unless (value = Filter.groupNames[v])?
      value
    else
      0

  ###
    2018-04-19 SBD: I still think 'both' should be 1000, but it breaks Zo.

    Why? Because the ValidationFilter sets default fields and the UserOwnedFilter
    throws errors if the user attempts to set fields they aren't allowed to manually
    set. Well, this means the UserOwnedFilter needs to fire BEFORE ValidationFilter.

    The real problem here is ValidationFilter actually acts differently client-side vs
    server-side. I'm beginning to think the "both" mode for a Filter actually doesn't
    make much sense. I think we DO want to have a client-side validator which is
    initialized with the exact same constraint as the server-side validator. However,
    I'm beginning to think it just makes more sense if they are actually different filters.

    Right now I'm overloading what "Validation" means - and overloading usually (always?)
    creates unecessary complexity.

    And guess what? Validation, and only as a pre-filter, is STILL the only example I've
    found where a "both" filter kind-of makes sense.

    If we split Validator into separate Client and Server, we can drop the whole "both"
    concept - which probably simplifies A LOT of code! ooo!
  ###
  locationPriorityBoost =
    client: 2000
    both:   0
    server: 0

  @getter
    priority: -> @group + locationPriorityBoost[@location]

  #################################
  # class instance methods
  #################################

  # NOTE!!! Filter instances must be stateless w.r.t. pipelines
  #   In other words, the same filter instance can be used on more than one pipeline.
  #   WHY? So we can inherit filters.
  #   WHY? So we can define global filters for all, or a subset, of the pipelines
  constructor: (options = {}) ->
    super
    {
      @serverSideOnly
      @clientSideOnly
      @name = @class.getName()

      # declarables
      @location
      @fields
      @group
      @filterFailures
      @after
      @before
    } = options

  @property "name"

  @setter
    nextHandler: (v)->
      throw new Error "depricated"

  shouldFilter: (processingLocation) ->
    switch @location
      when "server" then processingLocation != "client"
      when "client" then processingLocation != "server"
      when "both"   then true
      else throw new Error "Filter #{@getName()}: invalid filter location: #{location}"

  toString: -> @getName()

  getBeforeFilter: ({requestType, location}) -> @shouldFilter(location) && (@before[requestType] || @before.all)
  getAfterFilter:  ({requestType, location}) -> @shouldFilter(location) && (@after[requestType]  || @after.all)

  processBefore:  (request) -> @applyHandler request, @getBeforeFilter(request), request.verbose && "#{@getName()}-beforeFilter"
  processAfter:   (request) -> @applyHandler request, @getAfterFilter(request), request.verbose && "#{@getName()}-afterFilter"

  handleRequest: (request, filterChain, currentFilterChainIndex) ->
    @processBefore request
    .then (request) =>
      if request.isResponse
        request
      else
        (if nextHandler = filterChain[nextIndex = currentFilterChainIndex + 1]
          nextHandler.handleRequest request, filterChain, nextIndex
        else
          request.missing "no Handler for request type: #{request.type}"
        ).then (response) =>
          if response.isSuccessful || @filterFailures
            @processAfter response
          else
            response

  @getter
    logName:  -> @getName()
    inspectedObjects: ->
      "#{@getNamespacePath()}(#{@name})":
        toInspectedObjects @props

    props: -> {@location}
