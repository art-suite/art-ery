{w, Validator, defineModule, mergeInto, BaseObject} = require 'art-foundation'

defineModule module, class Config extends BaseObject
  @config:
    tableNamePrefix: ""

    # the location ArtEry is currently running on
    # "client", "server", or "both" - 'both' is the serverless mode for development & testing
    location: "client"

    apiRoot: "api"

    ###
    remoteServer examples:
      "http://localhost:8085"
      "http://domain.com"
      "https://domain.com"
    ###
    remoteServer: null

    # increase logging level with interesting stuff
    verbose: false

  @getPrefixedTableName: (tableName) => "#{@tableNamePrefix}#{tableName}"

  configureOptionsValidator = new Validator do ->
    validLocations = w "server client both"
    location: validate: (v) -> !v || v in validLocations

  @configure: (config = {}) =>
    configureOptionsValidator.validateSync config
    mergeInto @config, config, @config
