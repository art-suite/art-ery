{defineModule, BaseObject} = require 'art-foundation'

defineModule module, class Config extends BaseObject
  @classProperty tableNamePrefix: ""
