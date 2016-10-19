{select, defineModule, log, Promise, BaseObject, merge} = require 'art-foundation'

http = require 'http'

defineModule module, class PromiseHttp extends BaseObject
  @start: (options) ->
    new PromiseHttp(options).start options

  constructor: (options = {})->
    {handlers} = options
    @_handlers = options.handlers || []

  @getter "handlers"

  ###
  IN:
    handler: (request, data) -> promise.then (simpleResponse) ->
      IN: request is an IncomingMessaage (https://nodejs.org/api/http.html#http_class_http_incomingmessage)
      IN: data - a string for now, but might also be a Buffer later
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
    @_handlers.push handler

  start: (options = {}) ->
    {port} = options

    http.createServer (request, response) =>
      log request: select request, "url", "headers"

      data = ""
      request.on 'data', (chunk) =>
        log onData: chunk
        data = "#{data}#{chunk}"
      request.on 'end', =>
        Promise.then =>
          for handler in @handlers
            break if handled = handler request, data
          handled
        .then (handled) =>
          if handled
            {headers, json, data} = handled
            headers = merge headers, "Content-Type": 'application/json' if json
            response.setHeader k, v for k, v of headers || {}
            response.end if json then JSON.stringify json else data

    .listen port, ->
      console.log "#{options.name || 'PromiseHttpServer'} listening on: http://localhost:#{port}"
