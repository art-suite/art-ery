{
  defineModule, log, merge, Promise
  object, deepMerge, compactFlatten
  formattedInspect
  array
} = require 'art-foundation'

Pipeline = require './Pipeline'
KeyFieldsMixin = require './KeyFieldsMixin'
{AfterEventsFilter} = require './Filters'

# Note, with CafScript, all the above becomes:
# include &ArtFoundation, &ArtEry

# Note, with CafScript, this line becomes just:
# mixin UpdateAfterMixin
defineModule module, -> (superClass) -> class UpdateAfterMixin extends superClass
  # Requires AfterEventsFilter on any pipeline you want to subscribe to

  #######################
  # Class Declaration API
  #######################
  ###
  updateAfter vs afterEvent

  afterEvent is more basic, gives you more control, but lacks the special features
  updateAfter can deliver.

  afterEvent:
    Invokes the specified function when the AfterEvent fires for the specified
    type and pipeline. The return results is resolved if it is a promise, but unless
    the promise is rejected or an error is thrown, the result is ignored.

    That's it. That's all afterEvent does.

    SEE: AfterEventsFilter

  updateAfter:
    The specified function should return a propsObject or array-of-propsObjects
    (optionally via a promise).
    After the rootRequest(*) completes, all updateAfter props are aggregated and
    deep-merged (for the same pipeline+key) and then update is called for each
    unique pipeline+key pair.

    If any of the updates fail, the rootRequest fails.
    If any of the updatePropsFunctions fail, the triggering-request fails.

  updateAfter's key benefit:
    If you update the same record more than once for the same rootRequest via
    updateAfter functions, there will only be one 'update' request invoked.

  (*) Technically the update requests due to updateAfters are triggered
    after the root-most request on a pipeline that mixed in UpdateAfterMixin,
    not strictly the rootRequest. If you use the UpdateAfterMixin on all your
    pipelines, it will therefor always be the rootRequest.
  ###

  ###
  updateAfter:
    declare records in THIS pipeilne that should be updated AFTER
    requests complete against another pipeline (or this one).

  IN: eventMap looks like:
    requestType: triggeringPipelineName: updateItemPropsFunction

    updateItemPropsFunction: (response) -> updateItemProps
    IN: response is the ArtEry request-response for the request-in-progress on
      the specified triggeringPipelineName.
      (response.pipelineName == the specified triggeringPipelineName)

    OUT: props object OR an array (compactFlattened) of props objects
      props-objects:
        Must have 'key' set to a string
        All same-key props-objects are deepMerged in the order they are listed.
          (i.e. last has priority)

  EXAMPLE:
    class User extends UpdateAfterMixin Pipeline
      @updateAfter
        # Increment postCount for all visible posts created by a user.
        create: post: ({data:{userId, createdAt, invisible}}) ->
          if !invisible
            key:  userId
            data: lastPostCreatedAt: createdAt
            add:  visiblePostCount: 1

  ###
  @updateAfter: (eventMap) ->
    throw new Error "keyFields must be 'id'" unless @getKeyFieldsString() == "id"
    for requestType, requestTypeMap of eventMap
      for pipelineName, updateRequestPropsFunction of requestTypeMap
        AfterEventsFilter.registerPipelineListener @, pipelineName, requestType
        @_addUpdateAfterFunction pipelineName, requestType, updateRequestPropsFunction

  ###
  afterEvent: Add your own event handler after other pipeline's successful requests.
  If you return a promise:
    The original request won't complete (or succeed) until your returned promise resolves.
    If your promise is rejected, the original request is rejected.

  IN: eventMap looks like:
    requestType: pipelineName: (response) -> (ignored except for errors)
  ###
  @afterEvent: (eventMap) ->
    for requestType, requestTypeMap of eventMap
      for pipelineName, afterEventFunction of requestTypeMap
        AfterEventsFilter.registerPipelineListener @, pipelineName, requestType
        @_addAfterEventFunction pipelineName, requestType, afterEventFunction

  ########################
  # PRIVATE
  ########################

  @extendableProperty
    updatePropsFunctions: {}
    afterEventFunctions:  {}

  @_addUpdateAfterFunction: (pipelineName, requestType, updatePropsFunction) ->
    ((@extendUpdatePropsFunctions()[pipelineName]||={})[requestType]||=[])
    .push updatePropsFunction

  @_addAfterEventFunction: (pipelineName, requestType, afterEventFunction) ->
    ((@extendAfterEventFunctions()[pipelineName]||={})[requestType]||=[])
    .push afterEventFunction

  # OUT: updateItemPropsBykey
  @_mergeUpdateProps: (manyUpdateItemProps) ->
    object (compactFlatten manyUpdateItemProps),
      key: ({key}) -> key
      when: (props) -> props
      with: (props, inputKey, into) =>
        unless props.key
          log.error "key not found for one or more updateItem entries": {manyUpdateItemProps}
          throw new Error "#{@getName()}.updateAfter: key required for each updateItem param set (see log for details)"
        if into[props.key]
          deepMerge into[props.key], props
        else
          props

  @_applyAllUpdates: (response) ->
    # log UpdateAfterMixin: _applyAllUpdates: response.requestPath
    {updateRequestsByToUpdatePipeline} = response.context
    response.context.updateRequestsByToUpdatePipeline = null
    if updateRequestsByToUpdatePipeline
      Promise.deepAll updateRequestsByToUpdatePipeline
      .then (resolvedUpdateRequestsByToUpdatePipeline) =>
        Promise.all array resolvedUpdateRequestsByToUpdatePipeline, (updatePropsList, toUpdatePipelineName) =>
          Promise.all array @_mergeUpdateProps(updatePropsList), (props) =>
            # log UpdateAfterMixin: "#{toUpdatePipelineName}.update": {props}
            response.subrequest toUpdatePipelineName, "update", {props}
      .then =>
        # recurse in case there are new updates
        @_applyAllUpdates response
    else
      Promise.resolve()

  ###
  UpdateAfterMixinFilter provides the functionality of only triggering
  updates when the rootRequest(*) completes.
  ###
  @filter
    name: "UpdateAfterMixinFilter"
    group: "outter"
    filterFailures: true

    before: all: (request) ->
      request.context.updateAfterMixinDepth = (request.context.updateAfterMixinDepth || 0) + 1
      request

    after: all: (request) ->
      if request.type == "create" && request.pipelineName == "post"
        log UpdateAfterMixinFilter: after: request.requestPath, context: request.context
      p = if request.context.updateAfterMixinDepth == 1
        UpdateAfterMixin._applyAllUpdates request
      else
        Promise.resolve()
      p.then ->
        request.context.updateAfterMixinDepth--
        request

  @handleRequestAfterEvent: (request) ->
    {pipelineName: triggeringPipelineName, requestType} = request
    toUpdatePipeline = @singleton
    toUpdatePipelineName = toUpdatePipeline.pipelineName

    # Add all update-props functions to the context
    ((request.context.updateRequestsByToUpdatePipeline ||= {})[toUpdatePipelineName]||=[]).push array(
      @getUpdatePropsFunctions()[triggeringPipelineName]?[requestType]
      (updateRequestPropsFunction) => updateRequestPropsFunction.call toUpdatePipeline, request
    )

    # invoke and wait for any afterEvent functions
    Promise.deepAll array(
      @getAfterEventFunctions()[triggeringPipelineName]?[requestType]
      (afterEventFunction) => afterEventFunction.call toUpdatePipeline, request
    )
