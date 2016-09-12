Foundation = require 'art-foundation'
Request = require './Request'
Response = require './Response'

{BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone, CommunicationStatus} = Foundation
{toResponse} = Response
{success} = CommunicationStatus

module.exports = class Filter extends require './ArtEryBaseObject'

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

  ###
  IN: Request instance
    processNext: ->
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  process: (request, processNext) ->

    @processBefore request
    .then (beforeResult) =>
      if beforeResult instanceof Request
        processNext beforeResult
      else
        beforeResult # Response instance

    .then (response) =>
      return response unless response.status == success
      @processAfter response

  ###
  OUT:
    promise.then (Request or successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  processBefore: (request) ->
    Promise.then =>
      if beforeFilter = @beforeFilters[request.type] || @beforeFilters.all
        beforeFilter.call @, request
      else
        # pass-through if no filter
        request
    .then (beforeResult) ->
      if beforeResult instanceof Request
        beforeResult
      else
        toResponse beforeResult, request
    .catch (e) => toResponse e, request, true

  ###
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  processAfter: (response) ->
    Promise.then =>
      if afterFilter = @afterFilters[response.request.type] || @afterFilters.all
        afterFilter.call @, response
      else
        # pass-through if no filter
        response
    .then (afterResult) => toResponse afterResult, response.request
    .catch (e)          => toResponse e, response.request, true
