{randomBase62Character, ceil, defineModule, log, Validator, randomString, isString} = require 'art-foundation'
Filter = require '../Filter'
Uuid = require 'uuid'
Crypto = require 'crypto'

secret = randomString()

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
  log2_62 = Math.log2 62
  constructor: (options)->
    super
    @bits = options?.bits || 70
    throw new Error "too many bits: #{@bits}. max = 256" unless @bits <= 256
    @numChars = ceil @bits / log2_62

  @uuid: uuid = -> Uuid.v4()

  @getter
    ###
    We replace / and + with some other random a-zA-Z0-9 character for readability and general parse-friendlyness.

    Technically this makes our ID base62. Also technically, we should
    replace / and + with separatly generated randomBase62Character
    for each, but this gets very close to true base62 since rarely are there two of either,
    and even if there are, it's only a slight decrease in the random-range.
    ###
    compactUniqueId: ->
      Crypto.createHmac('sha256', secret).update(uuid()).digest 'base64'
      .slice 0, @numChars
      .replace /\//g, randomBase62Character()
      .replace /\+/g, randomBase62Character()

  @before
    create: (request) ->
      request.withMergedData
        id: if request.originatedOnServer
            request.data?.id || @compactUniqueId
          else
            throw new Error "specifying an ID for create is not allowed without request.originatedOnServer" if request.data?.id
            @compactUniqueId

  @fields
    id: Validator.fieldTypes.id
