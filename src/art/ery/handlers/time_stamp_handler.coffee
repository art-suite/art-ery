{log} = require 'art-foundation'
Handler = require '../handler'

module.exports = class TimeStampHandler extends Handler
  beforeCreate: (request) ->
    request.withMergedData
      createdAt: now = new Date
      updatedAt: now

  beforeUpdate: (request) ->
    request.withMergedData
      updatedAt: new Date
