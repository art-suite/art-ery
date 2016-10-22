###
Used for buidling the minimal node.js code to deploy for production.
Right now, this is tested with HEROKU, but it should work in other cases.

Basically, you will build a single JS file that inludes:

  require and init your pipelines
  require this file

See art-ery-heroku-dev for a concrete example. In fact, you can use that repository
as a starting point. All you need to do is require your own pipelines in
the index.coffe file.

###
require './src/Art'
throng = require 'throng'
{log} = require 'art-foundation'
Server = require './src/Art/Ery/.Server'

numWorkers = process.env.WEB_CONCURRENCY || 1
port = (process.env.PORT || Server.Main.defaults.port) | 0

start = -> Server.Main.start port: port

if numWorkers > 1
  throng
    start: start
    workers:  numWorkers
    lifetime: Infinity
else
  start()