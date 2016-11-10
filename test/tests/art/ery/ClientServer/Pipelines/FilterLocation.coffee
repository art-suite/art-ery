{defineModule, log, isString, present, CommunicationStatus, arrayWith} = require 'art-foundation'
{Response, Request, Pipeline, Session, Config} = require 'art-ery'
{success, failure, missing} = CommunicationStatus

isPresentString = (s) -> isString(s) && present s

defineModule module, class FilterLocation extends Pipeline

  @remoteServer "http://localhost:8085"

  requestWithLog = (request, name) ->
    request.withData customLog: arrayWith request.data?.customLog, "#{name}@#{Config.location}"

  @filter
    location: "client"
    name: "clientFilter"
    before: filterTest: (request) -> requestWithLog request, @name

  @filter
    location: "both"
    name: "bothFilter"
    before: filterTest: (request) -> requestWithLog request, @name

  @filter
    location: "server"
    name: "serverFilter"
    before: filterTest: (request) -> requestWithLog request, @name

  @handlers
    filterTest: (request) ->
      request.success data: customLog: arrayWith request.data?.customLog, "[handler@#{Config.location}]"
