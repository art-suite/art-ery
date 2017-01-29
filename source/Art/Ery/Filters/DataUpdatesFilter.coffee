{deepMerge, defineModule, log, Validator, m} = require 'art-foundation'
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

  @after all: (response) ->
    if response.isRootResponse
      if response.location != "server" && Neptune.Art.Flux && dataUpdates = response.props.dataUpdates
        log DataUpdatesFilter: updatesDectected: {dataUpdates}

        {models} = Neptune.Art.Flux
        for pipelineName, dataUpdatesByKey of dataUpdates when model = models[pipelineName]
          for key, data of dataUpdatesByKey
            log "#{model.name}.updateFluxStore": {key, data}
            model.updateFluxStore key, {data}

    else
      {key, type} = response
      if key && (type == 'create' || type == 'update')
        {data, pipelineName, rootRequest} = response
        rootRequest.responseProps = deepMerge rootRequest.responseProps,
          dataUpdates: "#{pipelineName}": "#{key}": response.data

    response
