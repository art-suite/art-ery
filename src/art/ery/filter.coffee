Foundation = require 'art-foundation'
Request = require './request'
Response = require './response'

{BaseObject, Promise, log} = Foundation
{toResponse} = Response

module.exports = class Filter extends BaseObject

  ###
  IN: Request instance
    processNext: ->
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  process: (request, processNext) ->

    @_processBefore request
    .then (beforeResult) =>
      if beforeResult instanceof Request
        processNext beforeResult
      else
        beforeResult # Response instance

    .then (response) =>
      @_processAfter response

  ####################
  # Overrides
  ####################
  beforeGet:    (request) -> request
  beforeCreate: (request) -> request
  beforeUpdate: (request) -> request
  beforeDelete: (request) -> request
  afterGet:     (response) -> response
  afterCreate:  (response) -> response
  afterUpdate:  (response) -> response
  afterDelete:  (response) -> response

  ####################
  # PRIVATE
  ####################

  ###
  OUT:
    promise.then (Request or successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  _processBefore: (request) ->
    Promise.then =>
      switch request.type
        when "get"    then @beforeGet request
        when "create" then @beforeCreate request
        when "update" then @beforeUpdate request
        when "delete" then @beforeDelete request
    .then (beforeResult) ->
      if beforeResult instanceof Request
        beforeResult
      else
        toResponse beforeResult, request
    .catch (e) ->
      toResponse e, request, true

  ###
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  _processAfter: (response) ->
    Promise.then =>
      switch response.request.type
        when "get"    then @afterGet response
        when "create" then @afterCreate response
        when "update" then @afterUpdate response
        when "delete" then @afterDelete response
    .then (afterResult) =>
      toResponse afterResult, response.request
    .catch (e) ->
      toResponse e, response.request, true
