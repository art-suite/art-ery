{each, formattedInspect, deepMerge, merge, defineModule, log, Validator, m, isFunction, objectHasKeys} = require 'art-foundation'
Filter = require '../Filter'

###
A) Populate rootRequest.dataUpdates
B) if Neptune.Art.Flux is defined, and this is the rootRequest/response
   Perform 'local updates'
###
###
TODO:
  Eventually we will want a way to say that some record updates should not be returned client-side.
  First pass
    - data has already gone through the after-pipeline, so any after-filters can removed fields
      the current user can't see. TODO: create privacy filters
    - if data is empty, then don't added it to updates. Nothing to add anyway. DONE
###
defineModule module, class DataUpdatesFilter extends Filter

  # for subrequests, this will still be on the server
  # for rootRequest, this will actually run on the app-client - which is where we need to do the Flux updates
  @location "both"

  getUpdatedUpdates = (response, fields)->
    {key, type, responseData} = response
    field = if response.isRootResponse && type == "get"
      "dataUpdates"
    else
      switch type
        when "create", "update" then "dataUpdates"
        when "delete" then "dataDeletes"

    if field && (responseData || key)
      {pipelineName} = response
      log getUpdatedUpdates: {field, key, responseData}
      responseData ||= response.pipeline.toKeyObject?(key || responseData) || {}
      key ||= response.pipeline.toKeyString responseData
      fields[field] = deepMerge fields[field], "#{pipelineName}": "#{key}": responseData

    fields

  @after all: (response) ->
    if response.isRootResponse && response.location != "server" && Neptune.Art.Flux
      {dataUpdates, dataDeletes} = response.props

      {dataUpdates, dataDeletes} = getUpdatedUpdates response, {dataUpdates, dataDeletes}

      {models} = Neptune.Art.Flux
      for pipelineName, dataUpdatesByKey of dataUpdates when isFunction (model = models[pipelineName])?.dataUpdated
        each dataUpdatesByKey, (data, key) ->
          model.dataUpdated key, data

      for pipelineName, dataDeletesByKey of dataDeletes when isFunction (model = models[pipelineName])?.dataDeleted
        each dataDeletesByKey, (data, key) -> model.dataDeleted key, data

    if !response.isRootResponse
      getUpdatedUpdates response, response.rootRequest.responseProps

    response
