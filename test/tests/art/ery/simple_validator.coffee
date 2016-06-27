Foundation = require 'art-foundation'

{
  merge, log, BaseObject, shallowClone
  isNumber, isString, isPlainObject, isPlainArray
} = Foundation

idRegExpStr = "[a-z0-9]+"
isId = (v) -> isString(v) && v.match ///^#{idRegExpStr}$///i
isHexColor = (v) -> isString(v) && v.match /^#([a-f0-9]{3})|([a-f0-9]{6})/i

module.exports = class SimpleValidator extends BaseObject
  # fieldTypes are just easy, pre-defined Objects with the right properties:
  # Usage:
  #   This:           @fields webPage: @fieldTypes.id
  #   is the same as: @fields webPage: validate: (v) -> isId v
  @fieldTypes: fieldTypes =
    id:     validate: (v) -> isId v
    color:  validate: (v) -> isHexColor v
    number: validate: (v) -> isNumber v
    date:
      validate:   (v) -> isString(v) || (v instanceof Date)
      preprocess: (v) -> if isString(v) then new Date v else v

    email:
      validate: (v) -> isString(v) && v.trim().match emailRegexp
      preprocess: (v) -> v.trim().toLowerCase()

    url:
      validate: (v) -> isString(v) && v.match urlRegexp
      preprocess: (v) -> normalizeUrl v # downcase protocol and domain name

    boolean:  validate: (v) -> v == true || v == false
    count:    validate: (v) -> isNumber v
    object:   validate: (v) -> isPlainObject v
    string:   validate: (v) -> isString v
    array:    validate: (v) -> isPlainArray v

    trimmedString:
      validate: (v) -> isString v
      preprocess: (v) -> v.trim()

  # for ArtEry use
  @validateArtery: (artery, validationsMap) ->
    validator = new SimpleValidator validationsMap
    artery.before "create", (request) -> request.withData validator.preCreate request.data
    artery.before "update", (request) -> request.withData validator.preUpdate request.data

  constructor: (fieldDeclarationMap) ->
    @_fieldProps = {}
    @addFields fieldDeclarationMap

  addFields: (fieldDeclarationMap) ->
    for field, fieldOptions of fieldDeclarationMap
      @_addField field, fieldOptions

  ###
  OUT:
    promise.then (validatedPreprocessedFields) ->
    .catch (validationFailureInfoObject) ->
  ###
  preCreate: (fields) ->
    if @requiredFieldsPresent(fields) && @presentFieldsValid fields
      Promise.resolve @preprocessFields fields
    else
      Promise.reject
        invalidFields: @invalidFields fields
        missingFields: @missingFields fields

  ###
  OUT:
    promise.then (validatedPreprocessedFields) ->
    .catch (validationFailureInfoObject) ->
  ###
  preUpdate: (fields) ->
    if @presentFieldsValid fields
      Promise.resolve @preprocessFields fields
    else
      Promise.reject
        invalidFields: @invalidFields fields

  ####################
  # VALIDATION CORE
  ####################
  presentFieldsValid: (fields) ->
    for fieldName, {validate} of @_fieldProps when validate && (value = fields[fieldName])? && !validate value
      return false
    true

  requiredFieldsPresent: (fields) ->
    for fieldName, {required} of @_fieldProps when required && !(fields[fieldName]? || fields[required]?)
      return false
    true

  ####################
  # PREPROCESS CORE
  ####################
  preprocessFields: (fields) ->
    processedFields = null
    for fieldName, {preprocess} of @_fieldProps when preprocess && (value = fields[fieldName])?
      if (v = preprocess oldV = fields[fieldName]) != oldV
        processedFields ||= shallowClone fields
        processedFields[fieldName] = v
    processedFields || fields

  ####################
  # VALIDATION INFO CORE
  ####################
  missingFields: (fields) ->
    for fieldName, {required} of @_fieldProps when required && !(fields[fieldName]? || fields[required]?)
      fieldName

  invalidFields: (fields) ->
    for fieldName, {validate} of @_fieldProps when validate && (value = fields[fieldName])? && !validate value
      fieldName

  ###################
  # PRIVATE
  ###################
  _addField: (field, options) ->
    @_fieldProps[field] = options
