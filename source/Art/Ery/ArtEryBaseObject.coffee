{defineModule} = require 'art-standard-lib'
{BaseClass} = require 'art-class-system'
ArtEry = require './namespace'

defineModule module, class ArtEryBaseObject extends BaseClass
  @abstractClass()
  @getter
    # TODO: how exactly do we want to configure if we are in productionEnvironment or not?

    # returns true if we are a productionEnvironment.
    productionEnvironment: -> false
    pipelines: -> ArtEry.pipelines
