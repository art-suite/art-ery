Foundation = require 'art-foundation'
Request = require './Request'
Response = require './Response'

{getInspectedObjects, defineModule, BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone, CommunicationStatus} = Foundation
{success, failure} = CommunicationStatus

defineModule module, class Filter extends require './ArtEryBaseObject'
  @location: "server" # 'server', 'client' or 'both'

  ################
  # class inheritable props
  ################
  @extendableProperty
    beforeFilters: {}
    afterFilters: {}
    fields: {}

  ############################
  # Class Declaration API
  ############################
  @fields: @extendFields

  ###
  IN: requestType, requestFilter
  IN: map from requestTypes to requestFilters

  requestFilter: (request) ->
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
  @before: (a, b) -> @extendBeforeFilters a, b if a
  before: (a, b) -> @extendBeforeFilters a, b if a

  ###
  IN: requestType, responseFilter
  IN: map from requestTypes to responseFilter

  responseFilter: (response) ->
    IN: Response instance
    OUT: return a Promise returning one of the list below OR just return one of the list below:
      Response instance
      anythingElse -> toResponse anythingElse

    To reject a request:
    - throw an error
    - return a rejected promise
    - or create a Response object with the appropriate fields
  ###
  @after: (a, b) -> @extendAfterFilters a, b if a
  after: (a, b) -> @extendAfterFilters a, b if a

  #################################
  # class instance methods
  #################################

  constructor: (options = {}) ->
    super
    {@serverSideOnly, @clientSideOnly, @name, @location} = options
    @name ||= @class.getName()
    @_location ||= @class.location || "server"
    @shouldFilter()
    @after options.after
    @before options.before

  @property "name",
    serverSideOnly: false
    clientSideOnly: false

  @property "location"

  shouldFilter: (processingLocation) ->
    switch @location
      when "server" then processingLocation != "client"
      when "client" then processingLocation != "server"
      when "both" then true
      else throw new Error "Filter #{@getName()}: invalid filter location: #{@location}"

  toString: -> @getName()
  getBeforeFilter: (requestType, location = "server") -> @shouldFilter(location) && (@beforeFilters[requestType] || @beforeFilters.all)
  getAfterFilter:  (requestType, location = "server") -> @shouldFilter(location) && (@afterFilters[requestType]  || @afterFilters.all)

  processBefore: (request) -> @_processFilter request, @getBeforeFilter request.type
  processAfter: (response) -> @_processFilter response, @getAfterFilter response.type

  ###
  OUT:
    promise.then (successful Request or Response instance) ->
    .catch (failingResponse) ->
  ###
  _processFilter: (responseOrRequest, filterFunction) ->
    Promise.then =>
      if filterFunction
        responseOrRequest.addFilterLog @
        filterFunction.call @, responseOrRequest
      else
        # pass-through if no filter
        responseOrRequest
    .then (result) => responseOrRequest.next result
    .catch (error) =>
      log.error(
        "Error Applying Filter"
        filter: @
        pipeline: responseOrRequest.pipeline?.name
        responseOrRequest: responseOrRequest
        error: error
      )
      responseOrRequest.next error, failure
