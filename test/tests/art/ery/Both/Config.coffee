Foundation = require 'art-foundation'
Ery = Neptune.Art.Ery

{merge, log, createWithPostCreate, CommunicationStatus, wordsArray} = Foundation
{missing} = CommunicationStatus
{Pipeline, Filter, config} = Ery

module.exports =

  suite: ->
    test "config.tableNamePrefix", ->
      config.tableNamePrefix = "AwesomeApp."
      pipeline = new class MyPipeline extends Pipeline
      assert.eq pipeline.tableName, "AwesomeApp.myPipeline"
