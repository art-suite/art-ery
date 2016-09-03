{log, wordsArray, isString, Validator} = require 'art-foundation'
{createDatabaseFilters} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    simplePipeline = new SimplePipeline()
    .filter createDatabaseFilters
      user: linkTo: "user", rquired: true
      message: requiredPresent: "trimmedString"

    assert.eq Object.keys(simplePipeline.fields), wordsArray "
      id
      createdAt
      updatedAt
      userId
      message
      "

  test "create", ->
    simplePipeline = new SimplePipeline()
    .filter createDatabaseFilters
      user: linkTo: "user", rquired: true
      message: requiredPresent: "trimmedString"

    simplePipeline.create
      user: id: "abc123", name: "George"
      message: "Hi!"
    .then (data) ->
      assert.eq data.message, "Hi!"
      assert.eq data.userId, "abc123"
      assert.isNumber data.createdAt
      assert.isNumber data.updatedAt
      assert.eq data.id, "0"

  # test "create", ->
  #   simplePipeline = new SimplePipeline()
  #   .filter UuidFilter

  #   simplePipeline.create {}
  #   .then ({id}) ->
  #     assert.isString id
