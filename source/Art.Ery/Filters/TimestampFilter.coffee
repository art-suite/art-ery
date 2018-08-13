{defineModule, log, Validator, m, toSeconds} = require 'art-standard-lib'
Filter = require '../Filter'

defineModule module, class TimestampFilter extends Filter

  constructor: ->
    super
    @group = "outer"

  # NOTE: This filter is generally added BEFORE the ValidationFitler, so it won't get preprocessed.
  @before
    create: (request) ->
      request.withMergedData m
        createdAt: now = toSeconds() + .5 | 0
        updatedAt: now
        # use existing values, if present
        request.data if request.originatedOnServer


    update: (request) ->
      request.withMergedData
        updatedAt: toSeconds() + .5 | 0
        # use existing values, if present
        request.data if request.originatedOnServer

  @fields
    createdAt: "secondsTimestamp"
    updatedAt: "secondsTimestamp"
