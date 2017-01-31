{each, formattedInspect, deepMerge, merge, defineModule, log, Validator, m, isFunction} = require 'art-foundation'
Filter = require '../Filter'

###
A) Populate rootRequest.dataUpdates
B) if Neptune.Art.Flux is defined, and this is the rootRequest/response
   Perform 'local updates'
###
defineModule module, class DataUpdatesFilter extends Filter

  # for subrequests, this will still be on the server
  # for rootRequest, this will actually run on the app-client - which is where we need to do the Flux updates
  @location: "both"

  getUpdatedUpdates = (response, fields)->
    {key, type} = response
    field = switch type
      when "create", "update" then "dataUpdates"
      when "delete" then "dataDeletes"

    if field
      {data, pipelineName} = response
      key ||= response.pipeline.toKeyString data
      if key
        fields[field] = deepMerge fields[field], "#{pipelineName}": "#{key}": response.data || true
      else
        console.warn noKey: {pipelineName, type, key, data}
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
