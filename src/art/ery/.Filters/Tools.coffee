{defineModule, log, isString, isFunction, Validator, hasKeys} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
SetUserIdFromSessionFilter = require './SetUserIdFromSessionFilter'
{normalizeFieldProps} = Validator

defineModule module, class Tools
  @createDatabaseFilters: (fields) ->
    if fields.userOwned
      fields.user = "required link"

    linkFields = {}
    otherFields = {}
    for k, v of fields when k != "userOwned"
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
      new ValidationFilter otherFields if hasKeys otherFields
      new LinkFieldsFilter linkFields if hasKeys linkFields
      new SetUserIdFromSessionFilter if fields.userOwned
    ]
