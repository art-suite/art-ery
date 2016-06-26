Foundation = require 'art-foundation'
{BaseObject, reverseForEach} = Foundation

toResponse = (responseOrError) ->
  if responseOrError instanceof Response
    responseOrError
  else if (request = responseOrError) instanceof Request
    new Response request, "failure", "no response generated"
  else
    new Response null, "failure", responseOrError

class Response extends BaseObject
  constructor: (@_request, @_status, dataOrError) ->
    @_data = null
    @_error = null
    if @_status == "success"
      @_data = dataOrError
    else
      @_error = dataOrError

class Request exports BaseObject
  constructor: (@_key, @_table, @_record) ->

module.exports = class Table extends BaseObject

  constructor: (@_name)->
    @_beforeHandlers =
      get: []
      update: []
      create: []
    @_afterHandlers =
      get: []
      update: []
      create: []

  @getter "name"

  get:    (key)         -> @_performClientAction "get",    key
  update: (key, record) -> @_performClientAction "update", key, record
  create: (key, record) -> @_performClientAction "create", key, record

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
    table: Table instance
    record: Object (if update or create)

  ###
  before: (action, handler) -> @_beforeHandlers[action].push handler

  ###
  IN:
    action: "get", "update", or "create"
    handler: (response) -> response or promise returning a repsponse

  If response.status is anything but "success", then further handlers are not called; that response is returned.

  response:
    request: the request
    data: record or array of records
    status: ArtFlux status value
    error: information about the error if status == "failure"

  ###
  after: (action, handler) -> @_afterHandlers[action].push handler

  ###################
  # PRIVATE
  ###################
  _performAction: (action, request) ->
    serializer = new ArtPromise.Serializer

    # perform beforeHandlers
    reverseForEach @_beforeHandlers[action], (handler) -> serializer.then handler

    # ensure we have a response
    serializer.then toResponse
    serializer.catch toResponse

    # if the response was not "success", skip all afterHandlers
    serializer.then (response) ->
      throw response if response.status != "success"
      response

    # preform afterHandlers
    @_afterHandlers[action].forEach (handler) -> serializer.then handler

    # ensture we have a response
    serializer.catch toResponse

  # client actions just return the data and update the local session object if successful
  # otherwise, they "reject" the whole response object.
  _performClientAction: (action, key, record) ->
    @_performAction action, new Request key, record, @getSession()
    .then (response) ->
      if response.status == "success"
        @setSession response.session
        response.data
      else
        throw repsponse