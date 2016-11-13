module.exports = (require "art-foundation/configure_webpack")
  entries: "index test"
  dirname: __dirname
  package:
    scripts:
      testServer: "./art-ery-server -r ./test/tests/Art/Ery/ClientServer/Pipelines -s ./test/public/"
    description: "
      A pipelined business-logic framework for cloud-backed data. ArtEry
      conceptially allows you to write apps 100% as client-code, but with the
      security and performance of cloud-code.
      "
    dependencies:
      "art-foundation": "git://github.com/imikimi/art-foundation.git"
      "art-events":     "git://github.com/imikimi/art-events.git"
      "art-flux":       "git://github.com/imikimi/art-flux.git"
      "express":        "^4.14.0"
      throng:           "^4.0.0"
      jsonwebtoken:     "^7.1.9"
