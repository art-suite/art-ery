Foundation = require 'art-foundation'
{Flux} = Neptune.Art
ArtEry = require 'art-ery'

{
  log
  CommunicationStatus
  select
  isString
  isFunction
  decapitalize
  merge
  Promise
  eq
  upperCamelCase
  arrayWith
  arrayWithElementReplaced
  formattedInspect
  propsEq
  defineModule
  arrayWithout
} = Foundation

{missing, success, pending} = CommunicationStatus

{FluxModel} = Flux

defineModule module, class ArtEryQueryFluxModel extends FluxModel
  @abstractClass()
  ###
  This class is designed to be extended with overrides:

  ###
  constructor: ->
    super null
    @register()

  loadData: (key) ->
    Promise.resolve @query key, @pipeline
    .then (data) => @localSort data

  @setter "recordsModel pipeline"
  @getter "recordsModel pipeline"

  #########################
  # OVERRIDEABLES
  #########################
  ###
  IN: will be the key (returned from fromFluxKey)
  OUT: array of singleModel records
    OR promise.then (arrayOfRecords) ->
  TODO:
    In the future we may wish to return other things beyond the array of records.
    Example:
      DynamoDb returns data for "getting the next page of records" in addition to the records.
      DynamoDb also returns other interesting stats about the query.

    If an array is returned, it will always be records. However, if an object is
    returned, then one of the fields will be records - and will go through the return
    pipeline, but the rest will be left untouched and placed in the FluxRecord's data field.
    Or should they be put in an auxiliary field???
  ###
  query: (key) -> []

  ###
  override for to sort records when updating local query data in response to local record changes
  ###
  localSort: (queryData) -> queryData

  ###
  override for custom merge
  This implementation is a streight-up merge using @recordsModel.dataHasEqualKeys

  IN:
    previousQueryData: array of records or null
    updatedRecordData: single record or null
  OUT: return null if nothing changed, else return a new array
  ###
  localMerge: (previousQueryData, updatedRecordData, wasDeleted) ->
    return null unless previousQueryData && (updatedRecordData || wasDeleted)

    unless previousQueryData?.length > 0
      return if wasDeleted then [] else [updatedRecordData]

    updatedRecordDataKey = @recordsModel.toKeyString updatedRecordData
    for currentRecordData, i in previousQueryData
      if updatedRecordDataKey == @recordsModel.toKeyString currentRecordData
        return if wasDeleted
          # deleted >> remove from query
          arrayWithout previousQueryData, i
        else if propsEq currentRecordData, updatedRecordData
          # no change >> no update
          log "saved 1 fluxStore update due to no-change check! (model: #{@name}, record-key: #{updatedRecordDataKey})"
          null
        else
          # change >> replace with newest version
          arrayWithElementReplaced previousQueryData, updatedRecordData, i

    # updatedRecordData wasn't in previousQueryData
    if wasDeleted
      null
    else
      arrayWith previousQueryData, updatedRecordData

  localMergeGivenQueryKey: (queryKey, singleRecordData, wasDeleted) ->
    queryKey && @localMerge @fluxStoreGet(queryKey)?.data, singleRecordData, wasDeleted

  ###############################
  # FluxModel overrides
  ###############################
  ###
  ArtEryFluxModel calls dataUpdated and dataDeleted from its
  dataUpdated and dataDeleted functions, respectively.
  ###
  dataUpdated: (queryKey, singleRecordData) ->
    if mergeResult = @localMergeGivenQueryKey queryKey, singleRecordData
      @updateFluxStore queryKey, data: @localSort mergeResult

  dataDeleted: (queryKey, singleRecordData) ->
    if mergeResult = @localMergeGivenQueryKey queryKey, singleRecordData, true
      @updateFluxStore queryKey, data: @localSort mergeResult
