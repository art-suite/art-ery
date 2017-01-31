{defineModule, log, present, isPlainArray, isString, isPlainObject, formattedInspect, array, object, each} = require 'art-foundation'

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
    keyFieldsString:  -> @class._keyFieldsString
    keyFields:        -> @class._keyFields

  # Overrides FluxModel's implementation
  toKeyString: (a) ->
    if isString a
      a
    else
      @validateKey a
      array @keyFields, (field) -> a[field]
      .join "/"

  toKeyObject: (a) ->
    {keyFields} = @
    @validateKey if isPlainObject a
      object @keyFields, (v) -> a[v]
    else if isString a
      object (a.split "/"), key: (v, i) -> keyFields[i]
    else {}

  dataWithoutKeyFields: (data) ->
    data && object data, when: (v, k) => not(k in @keyFields)

  dataHasEqualKeys: (data1, data2) -> @toKeyString(data1) == @toKeyString(data2)

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
