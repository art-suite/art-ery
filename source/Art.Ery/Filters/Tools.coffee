{present, defineModule, log, isString, isFunction, Validator, hasProperties, objectWithout} = require 'art-foundation'
UniqueIdFilter = require './UniqueIdFilter'
TimestampFilter = require './TimestampFilter'
ValidationFilter = require './ValidationFilter'
LinkFieldsFilter = require './LinkFieldsFilter'
UserOwnedFilter = require './UserOwnedFilter'
AfterEventsFilter = require './AfterEventsFilter'
DataUpdatesFilter = require './DataUpdatesFilter'
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
  @createDatabaseFilters: (fields = {}, PipelineClass) ->
    {id, userOwned} = fields
    if userOwned
      fields.user = "required link"
      if isString userOwned
        log.error "DEPRICATED"
        fields.user = "#{fields.user} #{userOwned}"
      fields = objectWithout fields, "userOwned"

    if id
      uniqueIdProps = id
      fields = objectWithout fields, "id"

    linkFields = {}
    otherFields = {}
    addValidationFilter = false
    for k, v of fields
      {link} = v = normalizeFieldProps v

      if link
        linkFields[k] = v
        otherFields[k] = "object"
      else
        addValidationFilter = true
        otherFields[k] = v

    [
      new LinkFieldsFilter fields: linkFields if hasProperties linkFields
      new ValidationFilter fields: otherFields, exclusive: true if addValidationFilter
      new AfterEventsFilter
      new DataUpdatesFilter
      new UniqueIdFilter uniqueIdProps unless present(PipelineClass?._keyFieldsString) && PipelineClass._keyFieldsString != "id"
      new TimestampFilter
      new UserOwnedFilter userOwned if userOwned
    ]
