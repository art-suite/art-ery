module.exports = [
  pipelines: (require './PipelineRegistry').pipelines
  session: (require './Session').singleton
]
