{defineModule, log, isString, isFunction, Validator, hasProperties} = require 'art-foundation'
UniqueIdFilter = require './UniqueIdFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
UserOwnedFilter = require './UserOwnedFilter'
{normalizeFieldProps} = Validator

defineModule module, class Tools
  @createDatabaseFilters: (fields = {}) ->
    if fields.userOwned
      fields.user = "link"

    linkFields = {}
    otherFields = {}
    for k, v of fields when k != "userOwned"
      {link} = v = normalizeFieldProps v

      if link
        linkFields[k] = v
      else
        otherFields[k] = v

    [
      new UserOwnedFilter if fields.userOwned
      new UniqueIdFilter
      new TimestampFilter
      new LinkFieldsFilter fields: linkFields if hasProperties linkFields
      new ValidationFilter fields: otherFields if hasProperties otherFields
    ]
