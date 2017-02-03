AfterEventsFilter = require './AfterEventsFilter'
module.exports = [
  require './Tools'

  # for testing
  _resetFilters: ->
    AfterEventsFilter._reset()
]
