{log} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'

module.exports = [
  createDatabaseFilters: (fields) ->
    linkFields = {}
    otherFields = {}
    for k, v of fields
      {linkTo, required} = v
      if linkTo
        linkFields[k] = v
        idFieldName = k + "Id"
        otherFields[idFieldName] = type: "trimmedString", required: !!required
      else
        otherFields[k] = v

    log linkFields: linkFields, otherFields: otherFields
    [
      new UuidFilter
      new TimestampFilter
      new ValidationFilter otherFields
      new LinkFieldsFilter linkFields
    ]
]
