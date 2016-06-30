{log} = require 'art-foundation'
Filter = require '../filter'

module.exports = class TimestampFilter extends Filter
  beforeCreate: (request) ->
    request.withMergedData
      createdAt: now = new Date
      updatedAt: now

  beforeUpdate: (request) ->
    request.withMergedData
      updatedAt: new Date
