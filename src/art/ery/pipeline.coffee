Foundation = require 'art-foundation'
{success, missing, failure} = require './ery_status'
{BaseObject, reverseForEach, Promise, log, isPlainObject, inspect} = Foundation
Response = require './response'
Request = require './request'
Filter = require './filter'

{toResponse} = Response

module.exports = class Pipeline extends BaseObject

  constructor: ->
    @_handlers = []

  @getter "handlers", name: -> @class.getName()

  get:    (key)       -> @_performClientAction "get",    key
  update: (key, data) -> @_performClientAction "update", key, data
  create: (data)      -> @_performClientAction "create", null, data
  delete: (key)       -> @_performClientAction "delete", key

  ###
  SESSIONS -
    server-side:
      the Request needs to continaun the Session, if there is one
      Response should have a session object as well, which could be different
        than the Request session, in which case it updates the session.
    client-side:
      we'd like to be able to get and possibly subscribe to the session


  ###

  ###
  OUT: Query instance

  Ex:
    {query} = myTable
    query.equal "myField", 123
    query.process()
    .then (records) ->
    , (response) ->
      {data, status, error} = response
  ###
  @getter
    query: ->


  # IN: instanceof Filter or class extending Filter
  # OUT: @
  addFilter: (filter) ->
    @_handlers.push filter = if filter instanceof Filter
      filter
    else
      new filter

    throw "filter isn't a filter: #{inspect filter}" unless filter instanceof Filter
    @

  ###################
  # Overrides
  ###################

  getSession: -> @_session ||= {}
  setSession: (@_session) ->

  ###################
  # PRIVATE
  ###################
  ###
  ###
  _performAction: (action, request) ->
    {handlers} = @
    handlerIndex = handlers.length - 1

    # IN: Request instance
    # OUT:
    #   promise.then (successful Response instance) ->
    #   .catch (unsuccessful Response instance) ->
    processNext = (request) ->
      if handlerIndex < 0
        Promise.resolve new Response request: request, status: failure, error: message: "no filter generated a Response"
      else
        handlers[handlerIndex--].process request, processNext

    processNext request

  # client actions just return the data and update the local session object if successful
  # otherwise, they "reject" the whole response object.
  _performClientAction: (action, key, data) ->
    @_performAction action, new Request
      action:   action
      key:      key
      pipeline:   @
      data:     data
      session:  @getSession()

    .then (response) =>
      {status, data, session} = response
      if status == success
        @setSession session if session
        data
      else
        throw response
