{array, log, createWithPostCreate, w, isString, Validator, w} = require 'art-foundation'
{createDatabaseFilters, KeyFieldsMixin} = Neptune.Art.Ery
SimplePipeline = require '../SimplePipeline'

SimplePipelineWithKeys = KeyFieldsMixin SimplePipeline

module.exports = suite: ->

  test "fields are set correctly", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @filter createDatabaseFilters
        user:   "required link"
        foo:    link: true, required: true
        bar:    link: "user"
        message: "present trimmedString"

    assert.eq Object.keys(myPipeline.fields).sort(), w "
      bar
      barId
      createdAt
      foo
      fooId
      id
      message
      updatedAt
      user
      userId
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      LinkFieldsFilter
      ValidationFilter
      AfterEventsFilter
      DataUpdatesFilter
      UniqueIdFilter
      TimestampFilter
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

    assert.eq Object.keys(myPipeline.fields).sort(), w "
      createdAt
      id
      updatedAt
      userId
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      LinkFieldsFilter
      AfterEventsFilter
      DataUpdatesFilter
      UniqueIdFilter
      TimestampFilter
      UserOwnedFilter
      "

  test "userOwned and another field", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
      @addDatabaseFilters
        userOwned: true
        myField: "strings"

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      LinkFieldsFilter
      ValidationFilter
      AfterEventsFilter
      DataUpdatesFilter
      UniqueIdFilter
      TimestampFilter
      UserOwnedFilter
      "

    assert.eq Object.keys(myPipeline.fields).sort(), w "
      createdAt
      id
      myField
      updatedAt
      user
      userId
      "
