Foundation = require 'art-foundation'
{BaseObject} = Foundation
{success} = require './ery_status'

module.exports = class Response extends BaseObject
  constructor: (@_request, @_status, dataOrError) ->
    @_data = null
    @_error = null
    if @_status == success
      @_data = dataOrError
    else
      @_error = dataOrError

  @getter "status, error, data, request",
    inspectObjects: ->
      [
        {inspect: => @class.namespacePath}
        request: @request, status: @status, data: @data, error: @error
      ]
