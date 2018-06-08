{defineModule, log, present, isPlainArray, isString, isPlainObject, formattedInspect, array, object, each} = require 'art-foundation'
{Validator} = require 'art-validation'

###
@primaryKey and @keyFields are synonymous
Usage:

  class MyModel extends KeyFieldsMixin Pipeline # or FluxModel or whatever
    # 1 key
    @primaryKey "foo"
    @keyFields "foo"
    @keyFields ["foo"]

    # 2 keys
    @keyFields "foo/bar"
    @keyFields ["foo", "bar"]

    # 3 keys
    @keyFields "foo/bar/baz"   # compound key with 3 fields
    @keyFields ["foo", "bar', "baz"]

    # Default:
    # @keyFields "id"

Note that order matters. @keyFields is a lists of strings. Forward slash (/) is
used as a delimiter, so it shouldn't be in the names of your key-fields. Ideally
each key field name should match: /[-._a-zA-Z0-9]+/
###

# when CafScript arrives, this line will just be:
# mixin PrimaryKeyMixin
defineModule module, -> (superClass) -> class KeyFieldsMixin extends superClass

  ###########################################
  # Class API
  # TODO: use Declarable
  ###########################################
  @getKeyFields:        -> @_keyFields
  @getKeyFieldsString:  -> @_keyFieldsString

  @primaryKey: keyFields = (a) ->
    if isString a           then @_keyFields = (@_keyFieldsString = a).split "/"
    else if isPlainArray a  then @_keyFieldsString = (@_keyFields = a).join "/"
    else throw new Error "invalid value: #{formattedInspect a}"

  @keyFields: keyFields

  ###########################################
  # Instance API
  ###########################################
  @getter
    keyFieldsString:  -> @_keyFieldsString  ?= @class._keyFieldsString
    keyFields:        -> @_keyFields        ?= @class._keyFields
    keyValidator:     -> @_keyValidator     ?= @class._keyValidator

  isRecord: (data) ->
    if isPlainObject data
      for keyField in @keyFields
        return false unless data[keyField]?
      true

  # Overrides FluxModel's implementation
  dataToKeyString: (a) ->
    @validateKey a
    array @keyFields, (field) -> a[field]
    .join "/"

  toKeyObject: (a) ->
    {keyValidator, keyFields} = @
    keyObject = @validateKey if isPlainObject a
      object @keyFields, (v) -> a[v]
    else if isString a
      object (a.split "/"), key: (v, i) -> keyFields[i]
    else {}
    if keyValidator
      # validateUpdate just means key-fields are only validated if present
      # the important thing is the preprocessor is applied
      keyObject = keyValidator.validateUpdate keyObject, context: "#{@pipelineName}: toKeyObject validation"
    keyObject

  dataWithoutKeyFields: (data) ->
    data && object data, when: (v, k) => not(k in @keyFields)

  validateKey: (key) ->
    {keyFields} = @
    each keyFields, (field) => unless present key[field]
      throw new Error "#{@class.getName()} missing key field(s): #{formattedInspect {missing: field, keyFields, key}}"
    key

  #################################
  # PRIVATE
  #################################
  @_keyFieldsString:  defaultKeyFieldsString = "id"
  @_keyFields:        [defaultKeyFieldsString]

  @_initFields: ->
    super
    fields = @getFields()
    @_keyValidator = new Validator keyFields = object @getKeyFields(),
      when: (v) => fields[v]
      with: (v) => fields[v]
