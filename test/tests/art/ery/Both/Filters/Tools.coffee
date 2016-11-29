{log, createWithPostCreate, wordsArray, isString, Validator, w} = require 'art-foundation'
{createDatabaseFilters} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: createDatabaseFilters: ->
  setup ->
    Neptune.Art.Ery.config.location = "both"


  teardown ->
    Neptune.Art.Ery.config.location = "client"

  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        user:   "required link"
        foo:    link: true, required: true
        bar:    link: "user"
        message: "present trimmedString"

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

  # test "create", ->
  #   MyPipeline.singleton = new SimplePipeline()
  #   .filter UuidFilter

  #   MyPipeline.singleton.create {}
  #   .then ({id}) ->
  #     assert.isString id
