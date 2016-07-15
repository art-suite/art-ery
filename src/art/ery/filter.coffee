Foundation = require 'art-foundation'
Request = require './request'
Response = require './response'

{BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone} = Foundation
{toResponse} = Response

module.exports = class Filter extends BaseObject

  ################
  # class inheritable props
  ################
  @getBeforeFilters: -> @getPrototypePropertyExtendedByInheritance "classBeforeFilters", {}
  @getAfterFilters:  -> @getPrototypePropertyExtendedByInheritance "classAfterFilters", {}
  @getFields:        -> @getPrototypePropertyExtendedByInheritance "classFields", {}

  ############################
  # Class Declaration API
  ############################
  @fields: (fields) -> mergeInto @getFields(), fields

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
  @before: (a, b) -> addFilters @getBeforeFilters(), a, b

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
  @after: (a, b) -> addFilters @getAfterFilters(), a, b

  addFilters = (filters, a, b) ->
    if isPlainObject map = a
      filters[type] = filterFunction for type, filterFunction of map
    else if a && b
      filters[a] = b

  #################################
  # class instance methods
  #################################
  @getter "fields beforeFilters afterFilters"

  constructor: ->
    @_fields = merge @class.getFields(), @_fields
    @_beforeFilters = shallowClone @class.getBeforeFilters()
    @_afterFilters  = shallowClone @class.getAfterFilters()

  before: (a, b) -> addFilters @getBeforeFilters(), a, b
  after:  (a, b) -> addFilters @getAfterFilters(), a, b

  ###
  IN: Request instance
    processNext: ->
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  process: (request, processNext) ->

    @_processBefore request
    .then (beforeResult) =>
      if beforeResult instanceof Request
        processNext beforeResult
      else
        beforeResult # Response instance

    .then (response) =>
      @_processAfter response

  ####################
  # PRIVATE
  ####################

  ###
  OUT:
    promise.then (Request or successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  _processBefore: (request) ->
    Promise.then =>
      if beforeFilter = @beforeFilters[request.type]
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
  _processAfter: (response) ->
    Promise.then =>
      if afterFilter = @afterFilters[response.request.type]
        afterFilter.call @, response
      else
        # pass-through if no filter
        response
    .then (afterResult) => toResponse afterResult, response.request
    .catch (e)          => toResponse e, response.request, true
