# generated by Neptune Namespaces v3.x.x
# file: tests/Art.Ery/Both/index.coffee

module.exports = require './namespace'
module.exports
.addModules
  AuthPipeline:     require './AuthPipeline'    
  Config:           require './Config'          
  FilterBase:       require './FilterBase'      
  SimplePipeline:   require './SimplePipeline'  
  UpdateAfterMixin: require './UpdateAfterMixin'
require './Filters'
require './Flux'