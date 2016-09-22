{defineModule, log, isString, isFunction, Validator, hasProperties} = require 'art-foundation'
UuidFilter = require './UuidFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
UserOwnedFilter = require './UserOwnedFilter'
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
      new UserOwnedFilter if fields.userOwned
      new UuidFilter
      new TimestampFilter
      new ValidationFilter otherFields if hasProperties otherFields
      new LinkFieldsFilter linkFields if hasProperties linkFields
    ]
