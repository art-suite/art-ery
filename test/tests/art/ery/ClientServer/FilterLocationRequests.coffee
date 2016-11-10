{log, createWithPostCreate, RestClient} = require 'art-foundation'
{Config, missing, Pipeline, pipelines, session} = Neptune.Art.Ery

module.exports = suite:

  basic: ->
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
      {location} = Config
      Config.location = "both"
      pipelines.filterLocation.filterTest returnResponseObject: true
      .then (response) ->
        Config.location = location
        assert.eq response.handledBy, "handler"
        assert.eq response.data.customLog, [
          "serverFilter@both"
          "bothFilter@both"
          "clientFilter@both"
          "[handler@both]"
        ]
