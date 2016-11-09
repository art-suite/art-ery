{ceil, defineModule, log, Validator, randomString} = require 'art-foundation'
Filter = require '../Filter'
Uuid = require 'uuid'
Crypto = require 'crypto'

hmac = Crypto.createHmac 'sha256', randomString()


defineModule module, class UniqueIdFilter extends Filter

  ###
  choosing bits:

    bitsCalc = (maximumExpectedRecordCount, probabilityOfCollisions) ->
      ceil log(maximumExpectedRecordCount / probabilityOfCollisions) / log 2

    maximumExpectedRecordCount = 10 ** 12   # 1 trillion
    probabilityOfCollisions = 10 ** -9      # 1 in a billion (9-sigma)

    default = bitsCalc 10 ** 12, 10 ** -9   # == 70

  What if I pick bits too small? Greate news!

    With backends that accept strings as IDs (like DynamoDb), you can
    always increase the bits later, as your record-set gets bigger.

    The new Ids' length will be different from the old ids, and therefor,
    are guaranteed not to collide with them.
  ###
  constructor: (options)->
    super
    @bits = options?.bits || 70
    throw new Error "too many bits: #{@bits}. max = 256" unless @bits <= 256
    @numChars = ceil @bits / 6

  @uuid: uuid = -> Uuid.v4()
  @compactUniqueId: compactUniqueId = (bits = 60)->

  @getter
    compactUniqueId: ->
      hmac.update(uuid()).digest 'base64'
      .slice 0, @numChars

  @before
    create: (request) ->
      request.withMergedData
        id: if @originatedOnServer
            request.data.id || @compactUniqueId
          else
            @compactUniqueId

  @fields
    id: Validator.fieldTypes.id
