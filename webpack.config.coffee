module.exports = (require "art-foundation/configure_webpack")
  entries: "index test"
  dirname: __dirname
  package:
    scripts:
      devServer: "./art-ery-server -r ./test/tests/Art/Ery/ClientServer/Pipelines"
    description: "
      A pipelined business-logic framework for cloud-backed data. ArtEry
      conceptially allows you to write apps 100% as client-code, but with the
      security and performance of cloud-code.
      "
    dependencies:
      "art-foundation": "git://github.com/imikimi/art-foundation.git"
      "art-events":     "git://github.com/imikimi/art-events.git"
      "art-flux":       "git://github.com/imikimi/art-flux.git"
