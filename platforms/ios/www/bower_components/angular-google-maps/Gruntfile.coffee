log = require('util').log
_ = require 'lodash'
kickoff = require 'karma-kickoff'
argv = require('yargs').argv

module.exports = (grunt) ->
  # Load the required plugins
  require('./grunt/bower')(grunt)
  [
    "grunt-contrib-uglify"
    "grunt-contrib-jshint"
    "grunt-contrib-concat"
    "grunt-contrib-clean"
    "grunt-contrib-connect"
    "grunt-contrib-copy"
    "grunt-contrib-watch"
    "grunt-open"
    "grunt-mkdir"
    "grunt-contrib-coffee"
    "grunt-conventional-changelog"
    "grunt-bump"
    'grunt-replace'
    'grunt-subgrunt'
    'grunt-debug-task'
    'grunt-curl'
    'grunt-verbosity'
    'grunt-webpack'
    'grunt-angular-architecture-graph'
    ].forEach (gruntLib) -> grunt.loadNpmTasks gruntLib

  #squishing this file done by moving grunt options out to its own file. This way we can focus on tasks!
  options = require('./grunt/options')(grunt)

  allExamples = grunt.file.expand('example/*.html')

  #map allExamples listed from grunt.file.expand to an open format of 'example' -> path
  allExamplesOpen = {}
  allExamples.forEach (path) ->
    root = path.replace('example/', '').replace('.html', '')
    pathValue = "http://localhost:3100/#{path}"
    allExamplesOpen[root] =
      path: pathValue

#  console.log allExamplesOpen, true

  showOpenType = (toIterate = allExamplesOpen) ->
    _(toIterate).each (v, k) ->
      log "#{k} -> #{v.path}"
  #showAllExamples()
  options.open = _.extend options.open, allExamplesOpen
  grunt.initConfig options

  grunt.registerTask 'build', ['verbosity', 'clean:dist', 'jshint', 'mkdir', 'coffee',
  'concat:libs', 'replace', 'webpack', 'concat:dist', 'concat:streetview'
  'copy']
  # Default task: build a release in dist/
  grunt.registerTask "default", ['bower', 'curl', 'build', 'uglify:dist', 'uglify:streetview', 'karma']

  # run default "grunt" prior to generate _SpecRunner.html
  grunt.registerTask "spec", [
    'bower', 'curl',
    'verbosity', "clean:dist", "jshint", "mkdir", "coffee", "concat:libs", "replace", "webpack", "concat",
    "copy", "karma", "open:jasmine", "watch:spec"]

  grunt.registerTask "coverage", ['connect:coverage','open:coverage', "watch:spec"]

  grunt.registerTask 'default-no-specs', [
    "clean:dist", "jshint", "mkdir", "coffee", "concat:libs", "replace", "concat:dist",
    "copy", "uglify:dist"]

  grunt.registerTask 'offline', ['default-no-specs', 'watch:offline']

  dev = ["clean:dist", "jshint", "mkdir", "coffee", "concat:libs", "replace", "webpack", "concat", "copy"]

  grunt.registerTask "dev", dev.concat ["uglify:distMapped", "uglify:streetviewMapped", "karma"]

  grunt.registerTask "fast", dev.concat ["karma"]

  grunt.registerTask "mappAll", [
    'bower', 'curl',
    "clean:dist", "jshint", "mkdir", "coffee", "concat:libs", "replace", "webpack", "concat", "uglify"
    "copy", "karma", "graph"]

  grunt.registerTask "build-street-view", ['clean:streetview','mkdir','coffee', 'concat:libs', 'replace',
    'concat:streetview', 'concat:streetviewMapped', 'uglify:streetview', 'uglify:streetviewMapped']

  grunt.registerTask "buildAll", "mappAll"

  # Run the example page by creating a local copy of angular-google-maps.js
  # and running a webserver on port 3100 with livereload. Web page is opened
  # automatically in the default browser.
  grunt.registerTask 'graph', ['angular_architecture_graph']

  grunt.registerTask 'bump-@-preminor', ['changelog', 'bump-only:preminor', 'mappAll', 'bump-commit']
  grunt.registerTask 'bump-@-prerelease', ['changelog','bump-only:prerelease', 'mappAll', 'bump-commit']
  grunt.registerTask 'bump-@', ['changelog','bump-only', 'mappAll', 'bump-commit']
  grunt.registerTask 'bump-@-minor', ['changelog','bump-only:minor', 'mappAll', 'bump-commit']
  grunt.registerTask 'bump-@-major', ['changelog','bump-only:major', 'mappAll', 'bump-commit']

  exampleOpenTasks = []

  _.each allExamplesOpen, (v, key) ->
    basicTask = "open:" + key
    #register individual task (runs by itself)

    grunt.registerTask key, ["fast", "clean:example", "connect:server", basicTask, "watch:all"]
    exampleOpenTasks.push basicTask

  allExamplesTaskToRun = ["fast", "clean:example", "connect:server"].concat(exampleOpenTasks).concat ['watch:all']

  listWithQuotes = (collection, doLog = true) ->
    last = collection.length - 1
    all = ''
    collection.forEach (t, i) ->
      all += if i < last then "'#{t}'," else "'#{t}'"
    if doLog
      return log all
    all

  grunt.registerTask 'listExamples', showOpenType
  grunt.registerTask 'listAllOpen', ->
    showOpenType(options.open)

  grunt.registerTask 'listAllExamplesTasks', ->
    listWithQuotes exampleOpenTasks

  grunt.registerTask 'allExamples', allExamplesTaskToRun

  grunt.registerTask 'server', ["connect:server", "watch:all"]
  grunt.registerTask 's', 'server'

  grunt.registerTask 'karma', 'karma runner', ->
    kickoff @async(),
      logFn: grunt.log.oklns
      configFile: require.resolve './karma.conf.coffee'

  grunt.registerTask 'karmaSpecific', 'karma runner', ->
    kickoff @async(),
      configFile: require.resolve './karma.conf.coffee'
      logFn: grunt.log.oklns
      appendFiles: argv.files.split(',')
      lengthToPop: 1
      reporters: ['mocha']

  grunt.registerTask 'karmaB', ['build', 'karmaSpecific']
  grunt.registerTask 'karmaSpecB', ['build', 'karma']
#to see all tasks available don't forget "grunt --help" !!!
