{combineReducers} = Redux

Share = require "./share.coffee"

rows = (state = [], {type, payload})->
  switch type
    when "row" then [state..., payload]
    when "clear" then []
    else state
yank = (state = '', {type, payload})->
  switch type
    when "yank" then payload
    else state
app = (state = '', {type, app, payload})->
  switch type
    when "choose" then app
    else state

byApp = (reducer)->
  (state = {"": reducer(undefined,{})}, action)->
    if action.app?
      state = $.extend {}, state
      state[action.app] = reducer state[action.app], action
    state

buffer = (state = {cursor:0,share:(new Share "")}, {type,payload})->
  {cursor,share} = state
  switch type
    when "edit" then payload
    when "receive"
      share.receive payload
      cursor = share.transpose payload.ted, cursor
      {cursor,share}        
    when "choose"
      state # implicit create in byApp
    when "cursor" then {cursor:payload,share}
    when "line" then {cursor:0,share}
    # when "historyNext", "historyPrevious" then cursor:null # "last" sentinel
    else state

prompt = (state = "X", {type, payload})->
  switch type
    when "prompt" then payload
    else state
history = (state = {offset:-1, log:[]}, {type, payload})->
  {offset, active, log} = state
  switch type
    when "historyAdd"
      log = [paylod, log...]
      {offset:-1, log}
    when "edit" then {offset:-1, log}
    when "line" then {offset:-1, log}
    when "historyPrevious"
      if offset < log.length - 1
        offset++
      {offset, log}
    when "historyNext"
      if offset < 0
        {offset,log}
      else
        offset--
        {offset, log}
    else state

error = (state = "", {type, payload})->
  switch type
    when "state.error" then payload
    else state

#   drumOn = (state = false, {type})->
#     switch type
#       when "drumToggle" then !state
#       else state

#   drumBuffer = (state = (new Share ""), {type})->

module.exports = combineReducers {
  rows, yank, app, state:
    byApp combineReducers {prompt,buffer,history,error}
}
