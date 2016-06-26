Foundation = require 'art-foundation'
{success, missing, failure} = require './ery_status'
{BaseObject, reverseForEach, Promise, log, isPlainObject} = Foundation
Response = require './response'
Request = require './request'

toResponse = (responseOrError, request) ->

  if responseOrError instanceof Response
    responseOrError
  else if (request = responseOrError) instanceof Request
    new Response request, failure, "no response generated"
  else if responseOrError instanceof Error
    console.error responseOrError, responseOrError.stack
    new Response request, failure, responseOrError
  else if isPlainObject responseOrError
    new Response request, success, responseOrError
  else if responseOrError?
    new Response request, failure, "request returned invalid data: #{responseOrError}"
  else
    new Response request, missing, "request returned: #{responseOrError}"

module.exports = class Artery extends BaseObject

  constructor: ->
    @_beforeHandlers =
      get:    [(request) => @_processGet request]
      update: [(request) => @_processUpdate request]
      create: [(request) => @_processCreate request]
      delete: [(request) => @_processDelete request]

    @_afterHandlers =
      get: []
      update: []
      create: []
      delete: []

  @getter name: -> @class.getName()

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

  ###
  IN:
    action: "get", "update", or "create"
    handler: (request) -> request or promise returing request
      or rejected promise returning response

  request:
    key: string
    artery: Artery instance
    data: Object (if update or create)

  ###
  before: (action, handler) -> @_beforeHandlers[action].push handler

  ###
  IN:
    action: "get", "update", or "create"
    handler: (response) -> response or promise returning a response

  If response.status is anything but success, then further handlers are not called; that response is returned.

  response:
    request: the request
    data: data or array of records
    status: ArtFlux status value
    error: information about the error if status == failure

  ###
  after: (action, handler) -> @_afterHandlers[action].push handler

  ###################
  # Overrides
  ###################

  getSession: -> @_session ||= {}
  setSession: (@_session) ->

  _processGet: (request) -> throw new Error "override @_processGet"
  _processUpdate: (request) -> throw new Error "override @_processUpdate"
  _processCreate: (request) -> throw new Error "override @_createKernel"
  _processDelete: (request) -> throw new Error "override @_processDelete"

  ###################
  # PRIVATE
  ###################
  _performAction: (action, request) ->
    serializer = new Promise.Serializer

    toResponseWithRequest = (v) -> toResponse v, request

    # put the request in the pipeline
    serializer.then -> request

    # perform beforeHandlers
    reverseForEach @_beforeHandlers[action], (handler) -> serializer.then handler

    # ensure we have a response
    serializer.then toResponseWithRequest
    serializer.catch toResponseWithRequest

    # if the response was not success, skip all afterHandlers
    serializer.then (response) ->
      throw response if response.status != success
      response

    # preform afterHandlers
    @_afterHandlers[action].forEach (handler) -> serializer.then handler

    # ensture we have a response
    serializer.catch toResponseWithRequest

  # client actions just return the data and update the local session object if successful
  # otherwise, they "reject" the whole response object.
  _performClientAction: (action, key, data) ->
    @_performAction action, new Request key, @, data, @getSession()
    .then (response) =>
      {status, data, session} = response
      if status == success
        @setSession session if session
        data
      else
        throw response
