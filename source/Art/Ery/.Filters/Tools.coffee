{defineModule, log, isString, isFunction, Validator, hasProperties, objectWithout} = require 'art-foundation'
UniqueIdFilter = require './UniqueIdFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
UserOwnedFilter = require './UserOwnedFilter'
{normalizeFieldProps} = Validator

defineModule module, class Tools
  ###
  TODO: I want to refactor "userOwned":

    Instead of:
      userOwned: true

    I want to specify the owner-field as:
      user: "owner"

    That allows the field-name to be customized, but
    more importantly, it makes it look like all the
    other field defs (consistency).

    Last, if we treat it as any other field-declaration keyword, we can do:
      user: "include owner"
  ###
  @createDatabaseFilters: (fields = {}) ->
    {id, userOwned} = fields
    if userOwned
      fields.user = "required link"
      if isString userOwned
        fields.user = "#{fields.user} #{userOwned}"
      fields = objectWithout fields, "userOwned"

    if id
      uniqueIdProps = id
      fields = objectWithout fields, "id"

    linkFields = {}
    otherFields = {}
    for k, v of fields
      {link} = v = normalizeFieldProps v

      if link
        linkFields[k] = v
      else
        otherFields[k] = v

    [
      new UniqueIdFilter uniqueIdProps
      new TimestampFilter
      new LinkFieldsFilter fields: linkFields if hasProperties linkFields
      new UserOwnedFilter if userOwned
      new ValidationFilter fields: otherFields if hasProperties otherFields
    ]
