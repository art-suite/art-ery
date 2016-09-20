{defineModule, log, isString, isFunction, Validator} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
{normalizeFieldProps} = Validator

defineModule module, class Tools
  @createDatabaseFilters: (fields) ->
    linkFields = {}
    otherFields = {}
    for k, v of fields
      {link, required, present} = normalizeFieldProps v

      if link
        linkFields[k] = v
        idFieldName = k + "Id"
        otherFields[idFieldName] =
          fieldType:  "trimmedString"
          required:   required
          present:    present
      else
        otherFields[k] = v

    [
      new UuidFilter
      new TimestampFilter
      new ValidationFilter otherFields
      new LinkFieldsFilter linkFields
    ]
