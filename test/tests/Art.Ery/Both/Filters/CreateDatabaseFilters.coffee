{timeout, array, log, createWithPostCreate, w, isString, Validator, w} = require 'art-foundation'
{createDatabaseFilters, KeyFieldsMixin} = Neptune.Art.Ery
SimplePipeline = require '../SimplePipeline'

SimplePipelineWithKeys = KeyFieldsMixin SimplePipeline

module.exports = suite:
 basics: ->

    test "fields are set correctly", ->
      {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
        @filter createDatabaseFilters fields:
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
        @filter createDatabaseFilters fields:
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
          fields:     {}
          userOwned:  true

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
          fields: myField: "strings"

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

  regressions: ->
    test "updatedAt preprocessor", ->
      {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipelineWithKeys
        @addDatabaseFilters
          fields: myField: "strings"

      myPipeline.create data: myField: "foo"
      .then ({id, createdAt, updatedAt}) ->
        assert.eq updatedAt, createdAt
        assert.eq updatedAt, updatedAt | 0
        myPipeline.update key: id, data: myField: "bar"
      .then ({id, createdAt, updatedAt}) ->
        assert.eq updatedAt, updatedAt | 0
