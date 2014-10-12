OutputMediator  = require 'yivo-node-log'
registry        = require 'yivo-node-registry'
_               = require 'lodash'

log = OutputMediator.create 'task-manager'

class TasksManager

  rLeadingDashes: /^[\s\-]*/
  rTrailingDashes: /[\s\-]*$/

  constructor: ->
    _.bindAll @, 'completeEvent', 'errorHandler', 'runTask'
    @numberOfErrors = 0
    @errorsThreshold = 25

    @prepareOptions()
    @applyOptions()
    @prepareTask()
    @loadTask()

  prepareTask: ->
    @taskName = process.argv[2]
    @loadTask()

  loadTask: ->
    log.ok "Root directory is '#{rootDirectory}'"

    for ext in ['coffee', 'js']
      return @task if _.isFunction @task
      try
        @taskLocation = rootDirectory + "/tasks/#{@taskName}.#{ext}"
        @task = require @taskLocation
      catch e

    throw "Task '#{@taskName}' not found in '#{rootDirectory}/tasks'" unless _.isFunction @task
    log.ok "Task resolved with '#{@taskLocation}'"

  runTask: ->
    if 'async' in @flags then @runAsync() else @runSync()

  runAsync: ->
    try
      @task()
      @completeHandler()
    catch err
      @errorHandler err

  runSync: ->
    Sync = require 'sync'
    Sync =>
      @task()
      @completeHandler()
    , @errorHandler

  prepareOptions: ->
    @flags = _.map process.argv.slice(3), (flag) =>
      flag.replace(@rLeadingDashes, '').replace @rTrailingDashes, ''

  applyOptions: ->
    OutputMediator.disable() if 'no-output' in @flags

  completeEvent: ->
    log.ok "Task '#{@taskName}' completed!"
    process.exit()

  errorHandler: (err) ->
    return unless err
    log.print 'err', err.sender, err.toString()
    if ++@numberOfErrors > @flags.errorsThreshold
      log.err('Too many errors. Exiting') and process.exit -1
    else
      setTimeout @runTask, 0

module.exports = TasksManager;