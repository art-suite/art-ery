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


    ###
      generating a secury HMAC privateSessionKey:

      in short, run: openssl rand -base64 16

      http://security.stackexchange.com/questions/95972/what-are-requirements-for-hmac-secret-key
      Recommends 128bit string generated with a "cryptographically
      secure pseudo random number generator (CSPRNG)."

      http://osxdaily.com/2011/05/10/generate-random-passwords-command-line/
      # 128 bits:
      > openssl rand -base64 16

      # 256 bits:
      > openssl rand -base64 32
    ###

    server:
      privateSessionKey: "todo+generate+your+one+unique+key" # 22 base64 characters == 132 bits

  @getPrefixedTableName: (tableName) => "#{@config.tableNamePrefix}#{tableName}"
