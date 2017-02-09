{w, Validator, defineModule, mergeInto, BaseObject, Configurable} = require 'art-foundation'

defineModule module, class ArtEryConfig extends Configurable
  @defaults
    tableNamePrefix: ""

    # the location ArtEry is currently running on
    # "client", "server", or "both" - 'both' is the serverless mode for development & testing
    location: "both"

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

  @getPrefixedTableName: (tableName) => "#{@config.tableNamePrefix}#{tableName}"
