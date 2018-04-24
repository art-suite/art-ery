{log, createWithPostCreate, isString, Validator, Promise, object, isFunction} = require 'art-foundation'
{Pipeline, Filters, pipelines, config} = Neptune.Art.Ery
{LinkFieldsFilter} = Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite:
  basic: ->

    trimFields = (fields) ->
      object fields, (props) ->
        object props, when: (v) -> !isFunction v

    test "fields are set correctly", ->
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new LinkFieldsFilter fields: fields =
          user: "required link"
          post: link: "post"

      assert.eq trimFields(MyPipeline.getFields()),
        userId:  dataType: 'string', fieldType: "trimmedString", pipelineName: "user", required: true, maxLength: 1024
        postId:  dataType: 'string', fieldType: "trimmedString", pipelineName: "post", maxLength: 1024

    test "linked objects get converted to ids for writing", ->
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new LinkFieldsFilter fields: fields =
          user: link: "user", required: true

      pipelines.myPipeline.create
        data: user: id: "abc123", name: "George"
      .then (data) ->
        assert.eq data, userId: "abc123", id: "0"

    test "autoCreate linked object triggers on writing", ->
      createWithPostCreate class Media extends SimplePipeline
        ;

      createWithPostCreate class Post extends SimplePipeline
        @filter new LinkFieldsFilter fields: fields =
          media: link: autoCreate: required: true

      pipelines.post.create
        data: media: url: url = "bar.com/foo"

      .then (data) ->
        assert.eq data, mediaId: "0", id: "0"
        pipelines.media.get key: "0"

      .then (media) ->
        assert.eq media.url. url
