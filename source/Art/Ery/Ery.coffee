module.exports = [
  pipelines: (require './PipelineRegistry').pipelines
  session: (require './Session').singleton
  package: _package = require "art-ery/package.json"
  version: _package.version
  config: require('./Config').config
]
