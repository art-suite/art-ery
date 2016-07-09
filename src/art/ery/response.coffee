Foundation = require 'art-foundation'
Request = require './request'
{BaseObject, inspect, isPlainObject, log} = Foundation
{success, missing, failure, validStatus} = require './ery_status'

module.exports = class Response extends BaseObject
  constructor: (options) ->
    @validate options
    @_request = options.request
    @_status = options.status
    @_data = options.data
    @_error = options.error

  validate: (options)->
    {request, status, data, error} = options
    throw "invalid status: #{inspect status}" unless validStatus status
    throw "invalid request: #{inspect request}" unless request instanceof Request
    if status == success
      throw "invalid data: #{inspect data}" unless isPlainObject data
      throw "error not expected for status: '#{status}'" if error
    else
      throw "data not expected for status: '#{status}'" if data
      throw "invalid error: #{inspect error}" unless isPlainObject error

  @getter "status error data request",
    isSuccessful: -> @_status == success
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]
    props: -> request: @request, status: @status, data: @data, error: @error

  ###
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  @toResponse: (data, request, reject) ->
    Promise.resolve data
    .then =>
      throw "request required" unless request

      throw data if data instanceof Error
      if data instanceof Response
        data
      else if !reject && data?
        if isPlainObject data
          new Response request: request, status: success, data: data
        else
          new Response request: request, status: failure, error: message: "request returned invalid data: #{inspect data}"

      else
        new Response request: request, status: missing, error: data || message: "missing data for key: #{inspect request.key}"

    .then (response) =>
      if response.isSuccessful
        Promise.resolve response
      else
        Promise.reject response
    .catch (e) =>
      return Promise.reject e if e instanceof Response
      console.error e, e.stack
      new Response request: request, status: failure, error: error: data, message: data.toString()

