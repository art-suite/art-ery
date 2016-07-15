{log} = require 'art-foundation'
Filter = require '../filter'

module.exports = class TimestampFilter extends Filter
  @before
    create: (request) ->
      log beforeCreate: request
      request.withMergedData
        createdAt: now = Date.now()
        updatedAt: now

    update: (request) ->
      request.withMergedData
        updatedAt: Date.now()
