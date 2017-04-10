{
  defineModule, log, merge, Promise
  object, deepMerge, compactFlatten
  formattedInspect
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

  IN: eventMap looks like:
    requestType: pipelineName: updateItemPropsFunction

    updateItemPropsFunction: (response) -> updateItemProps
    IN: response is the ArtEry request-response for the request-in-progress on
      the specified pipelineName.
      (response.pipelineName should always == pipelineName)

    OUT: plainObject OR an array (with arbitrary array-nesting) of plainObjects
      The plainObjects are all merged to form one or more AWS updateItem calls.
      They should follow the art-aws streamlined UpdateItem API.
      In general, they should be of the form:
        key: string or object # the DynamoDb item's primary key
        # and one or more of:
        set/item:             (field -> value map)
        add:                  (field -> value to add map)
        setDefault/defaults:  (field -> value to set if no value present)

      SEE: art-aws/.../UpdateItem for more

  EXAMPLE:
    class User extends DynamoDbPipeline
      @updateAfter
        create: post: ({data:{userId, createdAt}}) ->
          key:  userId
          data: lastPostCreatedAt: createdAt
          add:  postCount: 1

  ###

  @updateAfter: (eventMap) ->
    throw new Error "keyFields must be 'id'" unless @getKeyFieldsString() == "id"
    for requestType, requestTypeMap of eventMap
      for pipelineName, updateRequestPropsFunction of requestTypeMap
        AfterEventsFilter.registerPipelineListener @, pipelineName, requestType
        @_addUpdateAfterFunction pipelineName, requestType, updateRequestPropsFunction

  ###
  Add your own event handler after other pipeline's successful requests.
  If you return a promise:
    The original request won't complete (or succeed) until your returned promise resolves.
    If your promise is rejected, the original request is rejected.

  IN: eventMap looks like:
    requestType: pipelineName: (response) -> (ignored)
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

  ###
  Executes all @updatePropsFunctions appropriate for the current request.
  Then merge them together so we only have one update per unique record-id.
  ###
  emptyArray = []
  @handleRequestAfterEvent: (request) ->
    {pipelineName, requestType} = request

    updateRequestPropsPromises = for updateRequestPropsFunction in @getUpdatePropsFunctions()[pipelineName]?[requestType] || emptyArray
      Promise.then => updateRequestPropsFunction.call @singleton, request

    afterEventPromises = for afterEventFunction in @getAfterEventFunctions()[pipelineName]?[requestType] || emptyArray
      Promise.then => afterEventFunction.call @singleton, request

    Promise.all([
      Promise.all updateRequestPropsPromises
      Promise.all afterEventPromises
    ])
    .then ([resolvedUpdateRequestProps]) =>
      promises = for key, props of @_mergeUpdateProps resolvedUpdateRequestProps
        request.subrequest @getPipelineName(), "update", {props}

      Promise.all promises
