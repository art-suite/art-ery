{w, Validator, defineModule, mergeInto, BaseObject, Configurable} = require 'art-foundation'

defineModule module, class Config extends Configurable
  @defaults
    tableNamePrefix: ""

    # the location ArtEry is currently running on
    # "client", "server", or "both" - 'both' is the serverless mode for development & testing
    location: "both"

    # if true, sessions will be saved in the browser's localStorage
    #   and shared across windows for the same URL.
    # If false, sessions will be lost when the web-page is closed.
    #   Each window will have is own session regardless of URL.
    saveSessions: true

    apiRoot: "api"

    ###
    remoteServer examples:
      "http://localhost:8085"
      "http://domain.com"
      "https://domain.com"
      "//domain.com"  # this ensures the request stays HTTP or HTTPS based on the original html request
      true

    If remoteServer is true
      requests will still go to the remote server
      The remote URL, though, will just be "#{apiRoot}/..."

      This is a good setting for apps loaded from an HTML page on the same
      server as the remote-API.
    ###
    remoteServer: null

    # increase logging level with interesting stuff
    verbose: false

    # If true, @beforeFilterLog, @handledBy, @afterFilterLog are returned
    # Don't use in production :).
    returnProcessingInfoToClient: false


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
