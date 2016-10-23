jwt = require "jsonwebtoken"
{Promise} = require 'art-foundation'

module.exports = class PromiseJsonWebToken
  @sign: (payload, secretOrPrivateKey, options) ->
    Promise.withCallback (callback) -> jwt.sign payload, secretOrPrivateKey, options, callback

  @verify: (token, secretOrPrivateKey, options) ->
    Promise.withCallback (callback) -> jwt.verify token, secretOrPrivateKey, options, callback
