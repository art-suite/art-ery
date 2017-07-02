{log, createWithPostCreate, RestClient} = require 'art-foundation'
{missing, Pipeline, pipelines, session} = Neptune.Art.Ery

module.exports = suite: ->
  test "http://localhost:8085/static_asset.txt", ->
    RestClient.get "http://localhost:8085/static_asset.txt"
    .then (v) ->
      log v