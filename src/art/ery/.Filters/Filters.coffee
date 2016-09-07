{log, isString, isFunction} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'

module.exports = [
  createDatabaseFilters: (fields) ->
    linkFields = {}
    otherFields = {}
    for k, v of fields
      # NOTE: In node, something adds a native function, "link", to strings.
      # So, we need to strictly test for == true.
      if v.link == true || v.required?.link == true
        linkFields[k] = v
        idFieldName = k + "Id"
        otherFields[idFieldName] = fieldType: "trimmedString", required: !!v.required
      else
        otherFields[k] = v

    [
      new UuidFilter
      new TimestampFilter
      new ValidationFilter otherFields
      new LinkFieldsFilter linkFields
    ]
]
