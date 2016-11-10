{w, Validator, defineModule, mergeInto, BaseObject} = require 'art-foundation'

defineModule module, class Config extends BaseObject
  @tableNamePrefix: ""
  @getPrefixedTableName: (tableName) => "#{@tableNamePrefix}#{tableName}"

  # the location ArtEry is currently running on
  # "client", "server", or "both" - 'both' is the serverless mode for development & testing
  @location: "client"

  @apiRoot: "api"

  configureOptionsValidator = new Validator do ->
    validLocations = w "server client both"
    location: validate: (v) -> !v || v in validLocations

  @configure: (config = {}) =>
    configureOptionsValidator.validateSync config
    @location         = config.location         || @location
    @tableNamePrefix  = config.tableNamePrefix  || @tableNamePrefix
