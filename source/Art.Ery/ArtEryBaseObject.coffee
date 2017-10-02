{defineModule} = require 'art-standard-lib'
{BaseClass} = require 'art-class-system'
ArtEry = require './namespace'

defineModule module, class ArtEryBaseObject extends BaseClass
  @abstractClass()
  @getter
    pipelines: -> ArtEry.pipelines
