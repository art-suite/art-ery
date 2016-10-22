{inspect, formattedInspect, isJsonType, select, defineModule, log, Promise, BaseObject, merge, isPlainArray} = require 'art-foundation'

http = require 'http'

defineModule module, class PromiseHttp extends BaseObject
  @start: (options) ->
    new PromiseHttp(options).start options

  constructor: (options = {})->
    {handlers} = options
    @_commonResponseHeaders = options.commonResponseHeaders
    @_handlers = options.handlers || []
    @addApiHandler options.apiHandlers

  @getter "handlers"

  ###
  IN:
    handler: (request, data) -> promise.then (simpleResponse) ->
      IN: request is an IncomingMessaage (https://nodejs.org/api/http.html#http_class_http_incomingmessage)
      IN: data - a string for now, but might also be a Buffer later

  IN: hanlder: array of handlers; each handler gets added
  IN: null -> noop

  OUT:
    if falsish, then the next handler in the chain is tried
    else simpleResponse or promise returning simpleResponse

    simpleResponse:
      headers: simple object defining the response headers
      data: unintepreted response data
      json: JSON.stringified repsonse data
        # also sets the correct response headers

  ###
  # handler returns null if it passes on handling the request
  # handler returns a promise (or a value which will be wrapped in a promise) if it is handling the request
  addHandler: (handler) ->
    switch
      when !handler             then null
      when isPlainArray handler then @_handlers = @_handlers.concat handler
      else @_handlers.push handler

  ###
  IN: apiHandler: (request, plainObjectStructureInput) -> Promise.then (plainObjectStructureOutput) ->
  IN: apiHandler can be an array of apiHandlers to add
  IN: null -> noop

  apiHandlers don't need to manage:
    - parsing and encoding JSON
    - response headers

  apiHandler OUT:
    if the handler can't respond to that request
      null/false
    else if success
      plainObjectStructureOutput or a promise resolving to plainObjectStructureOutput
    else if failure
      throw error or return rejected promise
  ###
  addApiHandler: (apiHandler) ->
    switch
      when !apiHandler then null
      when isPlainArray apiHandler then @addApiHandler h for h in apiHandler
      else
        @addHandler (request, data) ->
          Promise.then ->
            JSON.parse data || "{}"
          .catch -> throw new Error "requested data was not valid JSON: #{data}"
          .then (parsedData) ->
            apiHandler request, parsedData
          .then (responseData) ->
            # log PromiseHttp: responseData: responseData
            return false unless responseData
            unless isJsonType responseData
              throw new Error "INTERNAL ERROR: api handler did not return a JSON compatible type: #{inspect responseData}"
            # log apiHandler_then: responseData
            headers: "Content-Type": 'application/json'
            data: if request.headers.accept?.match /json/
                JSON.stringify responseData
              else
                formattedInspect responseData

  start: (options = {}) ->
    {port} = options

    http.createServer (request, response) =>
      log "#{new Date} PromiseHttp request: #{request.method} #{request.url}"

      data = ""
      request.on 'data', (chunk) => data = "#{data}#{chunk}"

      request.on 'end', =>
        Promise.then =>
          # log requestHeaders: request.headers
          serilizer = new Promise.Serializer
          serilizer.then -> false
          for handler, i in @handlers
            do (handler, i) ->
              serilizer.then (previous) ->
                # log previous: previous, i: i
                previous || handler request, data
          serilizer

        .then (plainResponse) =>
          if plainResponse
            {headers, data} = plainResponse
            response.setHeader k, v for k, v of merge @_commonResponseHeaders, headers
            response.end data
          else
            log.error "REQUEST NOT HANDLED: #{request.method}: #{request.url}"

    .listen port, ->
      log "#{options.name || 'PromiseHttpServer'} listening on: http://localhost:#{port}"
