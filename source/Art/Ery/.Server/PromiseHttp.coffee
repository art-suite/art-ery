{
  each
  inspect, isPlainObject, formattedInspect, isJsonType, select, defineModule, log, Promise, BaseObject, merge, isPlainArray
  dateFormat
  inspectLean
  object
  CommunicationStatus
} = require 'art-foundation'

{success, missing, serverFailure, failure, clientFailure} = CommunicationStatus

http = require 'http'
querystring = require 'querystring'

defineModule module, class PromiseHttp extends BaseObject
  @start: (options) ->
    new PromiseHttp(options).start()

  constructor: (@options)->
    {handlers, @verbose} = @options ||= {}
    @_commonResponseHeaders = @options.commonResponseHeaders
    @_handlers = @options.handlers || []
    @addApiHandler @options.apiHandlers

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
          Promise.then -> JSON.parse data || "{}"
          .catch -> throw new Error "requested data was not valid JSON: #{data}"
          .then (parsedData) ->
            {url} = request
            [__, query] = url.split "?"
            merge parsedData,
              query && object querystring.parse(query), (v) ->
                try
                  JSON.parse v
                catch
                  v

          .then (parsedData) ->
            apiHandler request, parsedData

          .catch (error) ->
            log.error "#{getLogTime()}": PromiseHttp: apiHandler: {error}
            status: "failure"
            data: message:  "#{error}"

          .then (responseData) ->
            return false unless responseData
            unless isJsonType responseData
              throw new Error "INTERNAL ERROR: api handler did not return a JSON compatible type: #{formattedInspect responseData}"

            statusCode: switch responseData.status
              when success        then 200
              when missing        then 404
              when clientFailure  then 400
              else 500

            headers: "Content-Type": 'application/json'
            data: if request.headers.accept?.match /json/
                JSON.stringify responseData
              else
                formattedInspect responseData, 160

  getLogTime = ->
    dateFormat "UTC:yyyy-mm-dd_HH-MM-ss"

  _processRequestWithHandlers: (request, requestData) ->
    Promise.then =>
      serilizer = new Promise.Serializer
      serilizer.then -> false
      each @handlers, (handler, i) ->
        serilizer.then (previous) ->
          previous || handler request, requestData
      serilizer

  @getter middleware: ->
    (request, response, next) =>

      requestData = ""
      request.on 'data', (chunk) =>
        requestData = "#{requestData}#{chunk}"

      request.on 'end', =>
        @_processRequestWithHandlers request, requestData

        .then (plainResponse) =>
          log {plainResponse}
          if plainResponse
            {headers, data, statusCode = 200} = plainResponse


            # TODO: I want to move this logging into the Art.Ery server, where we have more specific data
            # I also don't want to log signed sessions - it's a security risk. But, we can log the parsed sessions, which is really what we want anyway.
            logObject = "#{request.method}": request.url
            logObject.in = requestData if requestData

            log "#{getLogTime().replace /\:/g, '_'}: pid: #{process.pid}, status: #{statusCode}, out: #{plainResponse?.data?.length || 0}bytes, #{inspectLean logObject}"
            if @verbose
              log
                requestData: try
                  JSON.parse requestData
                catch
                  requestData
                responseData: try
                  JSON.parse data
                catch
                  data

            response.statusCode = statusCode
            if (statusCode/100 | 0) == 5
              log.error "#{getLogTime()}": response: merge plainResponse,
                data: try JSON.parse data

            response.setHeader k, v for k, v of merge @_commonResponseHeaders, headers
            response.end data
          else if next
            next()
          else
            log.error "REQUEST NOT HANDLED: #{request.method}: #{request.url}"

        .catch (error) =>
          log.error "#{getLogTime()} PromiseHttp: #{request.method} #{request.url}, ERROR:", error
          console.error error
          response.end "#{getLogTime()} PromiseHttp: #{request.method} #{request.url}, ERROR: #{formattedInspect error}"

  start: ->
    {port, name} = @options
    staticOptions = @options.static
    log PromiseHttp: start:
      options: @options

    express = require 'express'
    app = express()
    app.use require('compression')()
    app.use @middleware
    if staticOptions
      log "serving statuc assets from: #{staticOptions.root}"
      app.use express.static staticOptions.root, merge staticOptions,
        maxAge: 3600*24*7 # 1 week
        setHeaders: (res) -> res.setHeader "Access-Control-Allow-Origin", "*" # CORS

    app.listen port, =>
      log "#{name || 'PromiseHttpServer'} listening on: http://localhost:#{port}"
