{log, createWithPostCreate, wordsArray, isString, Validator} = require 'art-foundation'
{createDatabaseFilters} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: createDatabaseFilters: ->
  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        user: required: link: true
        foo: link: true, required: true
        bar: link: "user"
        message: requiredPresent: "trimmedString"

    assert.eq Object.keys(MyPipeline.singleton.fields), wordsArray "
      id
      createdAt
      updatedAt
      userId
      fooId
      barId
      message
      "

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        user: link: "user", rquired: true
        message: requiredPresent: "trimmedString"

    MyPipeline.singleton.create
      user: id: "abc123", name: "George"
      message: "Hi!"
    .then (data) ->
      assert.eq data.message, "Hi!"
      assert.eq data.userId, "abc123"
      assert.isNumber data.createdAt
      assert.isNumber data.updatedAt
      assert.eq data.id, "0"

  # test "create", ->
  #   MyPipeline.singleton = new SimplePipeline()
  #   .filter UuidFilter

  #   MyPipeline.singleton.create {}
  #   .then ({id}) ->
  #     assert.isString id
