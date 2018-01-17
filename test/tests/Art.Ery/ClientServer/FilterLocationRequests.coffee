{log, objectWithout, createWithPostCreate, RestClient} = require 'art-foundation'
{config, missing, Pipeline, pipelines, session} = Neptune.Art.Ery

module.exports = suite: ->
  savedRemoteServer = null
  setup ->
    savedRemoteServer = pipelines.filterLocation.remoteServer

  teardown ->
    pipelines.filterLocation.class.remoteServer savedRemoteServer

  test "client location", ->
    pipelines.filterLocation.filterTest returnResponseObject: true
    .then (response) ->
      assert.eq response.data.customLog, [
        "bothFilter@client"
        "clientFilter@client"
        "serverFilter@server"
        "bothFilter@server"
        "[handler@server]"
        "bothFilter@server"
        "serverFilter@server"
        "clientFilter@client"
        "bothFilter@client"
      ]
      assert.eq objectWithout(response.handledBy, "time"),
        name: "POST http://localhost:8085/api/filterLocation-filterTest"

  test "both location", ->
    {location} = config
    pipelines.filterLocation.class.remoteServer null
    assert.eq "both", pipelines.filterLocation.location
    pipelines.filterLocation.filterTest returnResponseObject: true
    .then (response) ->
      config.location = location
      assert.eq response.data.customLog, [
        "serverFilter@both"
        "bothFilter@both"
        "clientFilter@both"
        "[handler@both]"
        "clientFilter@both"
        "bothFilter@both"
        "serverFilter@both"
      ]
      assert.eq objectWithout(response.handledBy, "time"), name: "filterTest-handler"
