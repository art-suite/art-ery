{log} = require 'art-foundation'
Filter = require '../filter'

module.exports = class TimestampFilter extends Filter
  @before
    create: (request) ->
      log beforeCreate: request
      request.withMergedData
        createdAt: now = new Date
        updatedAt: now

    update: (request) ->
      request.withMergedData
        updatedAt: new Date
