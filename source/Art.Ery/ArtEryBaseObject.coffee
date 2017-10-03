{defineModule} = require 'art-standard-lib'
{BaseClass} = require 'art-class-system'
ArtEry = require './namespace'
{config} = require './Config'

defineModule module, class ArtEryBaseObject extends BaseClass
  @abstractClass()
  @getter
    pipelines: -> ArtEry.pipelines
