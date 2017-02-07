{isString, defineModule, array, randomString, merge, log, formattedInspect} = require 'art-foundation'
{Pipeline, KeyFieldsMixin, DataUpdatesFilter} = require 'art-ery'

defineModule module, class CompoundKeys extends require './SimpleStore'
  @remoteServer "http://localhost:8085"

  @keyFields "postId/userId"
