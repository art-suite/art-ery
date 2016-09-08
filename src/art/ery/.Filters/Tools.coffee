{defineModule, log, isString, isFunction} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'

defineModule module, class Tools
  @createDatabaseFilters: (fields) ->
    linkFields = {}
    otherFields = {}
    for k, v of fields
      # NOTE: In node, something adds a native function, "link", to strings.
      # So, we need to strictly test for == true.
      link = !isString(v) && (v.link || v.required?.link)
      if link == true || isString link
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
