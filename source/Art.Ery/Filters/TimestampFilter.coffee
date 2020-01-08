{defineModule, log, Validator, merge, toSeconds} = require 'art-standard-lib'
Filter = require '../Filter'

defineModule module, class TimestampFilter extends Filter

  @group "outer"

  _requireValidTimestamp = (request, fieldName, data, now) ->
    if value = data[fieldName]
      request.require value <= now + 1, "#{fieldName} cannot be set more than 1 second in the future (now: #{now})"

  requireValidTimestamps = (request, data, now) ->
    Promise.all [
      _requireValidTimestamp request, "createdAt", data, now
      _requireValidTimestamp request, "updatedAt", data, now
    ]

  # NOTE: This filter is generally added BEFORE the ValidationFitler, so it won't get preprocessed.
  @before
    create: (request) ->
      data = merge
        createdAt: now = toSeconds() + .5 | 0
        updatedAt: now
        # use existing values, if present
        request.data if request.originatedOnServer

      requireValidTimestamps request, data, now
      .then -> request.withMergedData data

    update: (request) ->
      data = merge
        updatedAt: now = toSeconds() + .5 | 0
        # use existing values, if present
        request.data if request.originatedOnServer

      requireValidTimestamps request, data, now
      .then -> request.withMergedData data

  @fields
    createdAt: "secondsTimestamp"
    updatedAt: "secondsTimestamp"
