{each, formattedInspect, isArray, deepMerge, merge, defineModule, log, Validator, m, isFunction, objectHasKeys} = require 'art-foundation'
Filter = require '../Filter'

###
A) Populate context.dataUpdates
B) if Neptune.Art.Flux is defined, and this is the root request or resposne
   Perform 'local updates'
###
###
TODO:
  Eventually we will want a way to say that some record updates should not be returned client-side.
  First pass
    - data has already gone through the after-pipeline, so any after-filters can removed fields
      the current user can't see. TODO: create privacy filters
    - if data is empty, then don't add it to updates. Nothing to add anyway. DONE
###
defineModule module, class DataUpdatesFilter extends Filter

  # for subrequests, this will still be on the server
  # for root requests, there is work to do on both the client and server
  @location "both"

  constructor: ->
    super
    @group = "outer"

  addOneRecord = (response, fields, field, key, record) ->
    fields[field] = deepMerge fields[field], "#{response.pipelineName}": "#{key}": record

  getUpdatedUpdates = (response, fields)->
    {key, type, responseData} = response
    field =
      switch
        when /^(create|update)/.test type then "dataUpdates"
        when /^delete/.test          type then "dataDeletes"

    if field
      if isArray responseData
        for record in responseData
          key = response.pipeline.toKeyString record
          addOneRecord response, fields, field, key, record
      else if key || response.pipeline.isRecord responseData
        responseData ||= response.pipeline.toKeyObject?(key || responseData) || {}
        key ||= response.pipeline.toKeyString responseData
        addOneRecord response, fields, field, key, responseData

    fields

  @after all: (response) ->
    if response.isRootRequest
      @applyFluxUpdates response if response.location != "server" && Neptune.Art.Flux

      if response.location != "client"
        {dataUpdates, dataDeletes} = response.context
        response.with props: merge response.responseProps, {dataUpdates, dataDeletes}
      else
        response
    else
      @addUpdatesToResponse response
      response

  applyFluxUpdates: (response) ->
    # if we are client-side with a remote server, they will be in responseProps
    # ELSE they will be in context...
    {responseProps, context} = response
    dataUpdates = merge context.dataUpdates, responseProps.dataUpdates
    dataDeletes = merge context.dataDeletes, responseProps.dataDeletes

    {dataUpdates, dataDeletes} = getUpdatedUpdates response, {dataUpdates, dataDeletes}

    {models} = Neptune.Art.Flux
    for pipelineName, dataUpdatesByKey of dataUpdates when isFunction (model = models[pipelineName])?.dataUpdated
      each dataUpdatesByKey, (data, key) ->
        # log applyFluxUpdates: dataUpdated: {type: response.type, model, key, data: data?.id}
        model.dataUpdated key, data

    for pipelineName, dataDeletesByKey of dataDeletes when isFunction (model = models[pipelineName])?.dataDeleted
      each dataDeletesByKey, (data, key) ->
        # log applyFluxUpdates: dataDeleted: {model, key, data}
        model.dataDeleted key, data

  addUpdatesToResponse: (response) ->
    getUpdatedUpdates response, response.context
