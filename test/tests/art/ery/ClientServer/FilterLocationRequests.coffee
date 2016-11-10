{log, createWithPostCreate, RestClient} = require 'art-foundation'
{missing, Pipeline, pipelines, session} = Neptune.Art.Ery

module.exports = suite:

  basic: ->
    test "filterTest", ->
      pipelines.filterLocation.filterTest()
      .then (result) ->
        assert.eq result.customLog, [
          "bothFilter@client"
          "clientFilter@client"
          "serverFilter@server"
          "bothFilter@server"
          "[handler@server]"
        ]
