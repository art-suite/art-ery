{BaseObject} = require 'art-foundation'

module.exports = class ArtEryBaseObject extends BaseObject
  @getter
    # TODO: how exactly do we want to configure if we are in productionEnvironment or not?

    # returns true if we are a productionEnvironment.
    productionEnvironment: -> false
