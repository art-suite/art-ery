{log, createWithPostCreate, RestClient} = require 'art-foundation'
{config, missing, Pipeline, pipelines, session} = Neptune.Art.Ery

module.exports = suite: ->

  test "client location", ->
    pipelines.filterLocation.filterTest returnResponseObject: true
    .then (response) ->
      assert.eq response.handledBy, "POST http://localhost:8085/api/filterLocation-filterTest"
      assert.eq response.data.customLog, [
        "bothFilter@client"
        "clientFilter@client"
        "serverFilter@server"
        "bothFilter@server"
        "[handler@server]"
      ]

  test "both location", ->
    {location} = config
    config.location = "both"
    pipelines.filterLocation.filterTest returnResponseObject: true
    .then (response) ->
      config.location = location
      assert.eq response.handledBy, handler: "filterTest"
      assert.eq response.data.customLog, [
        "serverFilter@both"
        "bothFilter@both"
        "clientFilter@both"
        "[handler@both]"
      ]
