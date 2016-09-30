{BaseObject, defineModule} = require 'art-foundation'
ArtEry = require './namespace'

defineModule module, class ArtEryBaseObject extends BaseObject
  @abstractClass()
  @getter
    # TODO: how exactly do we want to configure if we are in productionEnvironment or not?

    # returns true if we are a productionEnvironment.
    productionEnvironment: -> false
    pipelines: -> ArtEry.pipelines
