{array, log, createWithPostCreate, w, isString, Validator, w} = require 'art-foundation'
{createDatabaseFilters, KeyFieldsMixin} = Neptune.Art.Ery
SimplePipeline = require '../SimplePipeline'

SimplePipelineWithKeys = KeyFieldsMixin SimplePipeline

module.exports = suite: createDatabaseFilters: ->

  test "fields are set correctly", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @filter createDatabaseFilters
        user:   "required link"
        foo:    link: true, required: true
        bar:    link: "user"
        message: "present trimmedString"

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      fooId
      barId
      message
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      ValidationFilter
      AfterEventsFilter
      DataUpdatesFilter
      "

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @filter createDatabaseFilters
        user: required: link: "user"
        message: "present trimmedString"

    MyPipeline.singleton.create
      data:
        user: id: "abc123", name: "George"
        message: "Hi!"
    .then (data) ->
      assert.eq data.message, "Hi!"
      assert.eq data.userId, "abc123"
      assert.isNumber data.createdAt
      assert.isNumber data.updatedAt
      assert.match data.id, /^[-_a-zA-Z0-9\/\:]{12}$/

  test "userOwned only field", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @filter createDatabaseFilters
        userOwned: true

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      UserOwnedFilter
      AfterEventsFilter
      DataUpdatesFilter
      "

  test "userOwned and another field", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @addDatabaseFilters
        userOwned: true
        myField: "strings"

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      UserOwnedFilter
      ValidationFilter
      AfterEventsFilter
      DataUpdatesFilter
      "

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      myField
      "
