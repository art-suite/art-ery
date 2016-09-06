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
} = Foundation

{missing, failure, success, pending} = CommunicationStatus

{FluxModel} = Flux

module.exports = class ArtEryQueryFluxModel extends FluxModel
  ###
  This class is designed to be extended with overrides:

  ###
  constructor: ->
    super null
    @register()

  loadData: (key) ->
    Promise.resolve @query key, @pipeline

  @setter "recordsModel pipeline"
  @getter "recordsModel pipeline"

  ###
  OVERRIDE
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
  OVERRIDE
  IN: single record
  OUT: string key for the query results that should contain this record
  ###
  queryKeyFromRecord: (record) -> ""

  ###
  OVERRIDE
  override for to sort records when updating local query data in response to local record changes
  ###
  localSort: (queryKey, queryData) -> queryData

  ###
  OVERRIDE
  override for custom merge
  This implementation is a streight-up merge using @recordsModel.keysEqual

  IN:
    previousQueryData: array of records or null
    updatedRecordData: single record or null
  OUT: return preciousQueryData if nothing changed, else return a new array
  ###
  localMerge: (previousQueryData, updatedRecordData) ->
    return previousQueryData unless updatedRecordData
    return [updatedRecordData] unless previousQueryData?.length > 0

    for el, i in previousQueryData
      if @recordsModel.keysEqual el, updatedRecordData
        return arrayWithElementReplaced previousQueryData, updatedRecordData, i

    arrayWith previousQueryData, updatedRecordData

  ###
  OVERRIDE
  localUpdate gets called whenever whenever a fluxStore entry is created or updated for the recordsModel.

  Can override for custom behavior!

  This implementation assumes there is only one possible query any particular record will belong to,
  and it assumes the queryKey can be computed via @queryKeyFromRecord.

  NOTE: @queryKeyFromRecord must be implemented!
  ###
  localUpdate: (updatedRecordData) ->
    return unless updatedRecordData
    queryKey = @queryKeyFromRecord? updatedRecordData
    throw new Error "invalid queryKey from #{formattedInspect updatedRecordData}" unless isString queryKey
    return unless fluxRecord = @fluxStoreGet queryKey
    @updateFluxStore queryKey, data: @localSort @localMerge fluxRecord.data, updatedRecordData
