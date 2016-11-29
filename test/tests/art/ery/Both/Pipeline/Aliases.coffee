{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline, pipelines} = Neptune.Art.Ery

module.exports = suite: ->
  test "aliases don't currently add actual alises in pipelines", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @aliases "MyPipelineAlias"

    assert.eq pipelines.myPipelineAlias, undefined
    assert.eq MyPipeline.getAliases(), myPipelineAlias: true

  test "second aliases call replaces first", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @aliases "MyPipelineAlias"
      @aliases "FooLand"

    assert.eq MyPipeline.getAliases(), fooLand: true

  test "aliases are not inherited", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @aliases "MyPipelineAlias"

    createWithPostCreate class MySubPipeline extends MyPipeline
      @aliases "MySubPipelineAlias"

    assert.eq MyPipeline.getAliases(), myPipelineAlias: true
    assert.eq MySubPipeline.getAliases(), mySubPipelineAlias: true

  test "two pipelines with different aliases are distinct", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @aliases "MyPipelineAlias"

    createWithPostCreate class MyOtherPipeline extends Pipeline
      @aliases "MyOtherPipelineAlias"

    assert.eq MyPipeline.getAliases(), myPipelineAlias: true
    assert.eq MyOtherPipeline.getAliases(), myOtherPipelineAlias: true
