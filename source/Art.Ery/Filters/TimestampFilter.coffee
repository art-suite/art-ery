{defineModule, log, Validator, m, toSeconds} = require 'art-standard-lib'
Filter = require '../Filter'

defineModule module, class TimestampFilter extends Filter

  constructor: ->
    super
    @group = "outter"

  @before
    create: (request) ->
      request.withMergedData m
        createdAt: toSeconds now = Date.now()
        updatedAt: toSeconds now
        # use existing values, if present
        request.data if request.originatedOnServer


    update: (request) ->
      request.withMergedData
        updatedAt: toSeconds Date.now()
        # use existing values, if present
        request.data if request.originatedOnServer

  @fields
    createdAt: "secondsTimestamp"
    updatedAt: "secondsTimestamp"
