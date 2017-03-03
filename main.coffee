[recl,rele]                    = [React.createClass, React.createElement]
{div, u, pre, span}            = React.DOM
TreeStore                      = window.tree.util.store
{registerComponent}            = window.tree.util.actions

{createStore, combineReducers} = Redux
{Provider, connect}            = ReactRedux

str = JSON.stringify
Share = require "./share.coffee"

reducers = do ->
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
        cursor = share.transpose payload, cursor
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

  combineReducers {rows, app, state:
    byApp combineReducers {prompt,buffer,history,error}}

stateToProps = ({yank,rows,app,state})->
  {prompt,buffer:{share,cursor},history,error} = state[app]
  if app is ''
    prompt = (k for k,v of state).join(', ') + '# '  
  input = 
    if history.offset >= 0
      history.log[history.offset] # editable mb?
    else share.buf
  {yank,rows,app,state,prompt,share,cursor,input,error}

noPad = padding: 0

Prompt = ({prompt,cursor,input})->
  cur =  cursor #- prompt.length
  buf =  input + " "
  pre {style:noPad}, prompt,
    span {style: background: 'lightgray'},
      buf[...cur], (u {}, buf[cur] ? " "), buf[cur+1 ..]
      # "⧖ " history.offset

Matr = ({rows,app,prompt,input,cursor}) ->
  div {},
    for lin,key in rows
      pre {key,style:noPad}, lin, " "
    rele Prompt, {prompt,input,cursor,key: "prompt"}

Sole = connect(stateToProps) ({rows,app,prompt,input,cursor,error})->
  (div {},
     (div {id:"err"},error)
     (rele Matr, {rows,app,prompt,input,cursor})
  )

IO = connect((stateToProps),(dispatch)-> Actions: Actions dispatch) recl
  render: -> div {}
  componentWillUnmount: -> Mousetrap.handleKey = @_defaultHandleKey
  componentDidMount: ->
    @_defaultHandleKey = Mousetrap.handleKey 
    Mousetrap.handleKey = (char, mod, e)=>
      {mod, key} = toKyev {char, mod, type:e.type}
      if key
        e.preventDefault()
        {Actions, app, share,cursor,input,yank} = @props
        Actions.eatKyev mod, key, app, {share,cursor,input,yank}
        
setTimeout -> # XX
  TreeStore.dispatch registerComponent "sole", recl
    getInitialState: ->
      store = createStore reducers, window.__REDUX_DEVTOOLS_EXTENSION__()
      (Actions store.dispatch).join @props["data-app"]
      {store}
    render: ->
      rele Provider, {store:@state.store},
        div {},
          rele IO
          rele Sole, @props
  
toKyev = ({char, mod, type})->
  norm = {
    capslock:  'caps'
    pageup:    'pgup'
    pagedown:  'pgdn'
    backspace: 'baxp'
    enter:     'entr'
  }

  key = switch
    when char.length is 1
      if type is 'keypress'
        chac = char.charCodeAt(0)
        if chac < 32          # normalize ctrl keys
          char = String.fromCharCode chac | 96
        str: char
    when type is 'keydown'
      if char isnt 'space'
        act: norm[char] ? char
    when type is 'keyup' and norm[key] is 'caps'
      act: 'uncap'
  if (key?.act in mod)
    {}
  else {mod, key}
  
Actions = (_dispatch)->
  flash: ($el, background)->
    $el.css {background}
    if background
      setTimeout (=> @flash $el,''), 50
  bell: -> @flash ($ 'body'), 'black'
    
  dispatch: (action)->
    type = [k for k of action].join " "
    _dispatch {type,payload:action[type]}

  dispatchTo: (app,action)->
    type = [k for k of action].join " "
    _dispatch {type,app,payload:action[type]}

  choose: (app)-> @dispatchTo app, {"choose"}
  
  print: (row)-> @dispatch {row}
    
  peer: (ruh,app) ->
    if ruh.map then return ruh.map (rul)=> @peer rul, app
    switch Object.keys(ruh)[0]
      when 'out' then @print ruh.out
      when 'txt' then @print ruh.txt
      when 'tan' then ruh.tan.trim().split("\n").map @print
      when 'pro' then @dispatchTo app, prompt: ruh.pro.cad
      when 'pom' then @dispatchTo app, prompt: _.map ruh.pom, ({text})->text
      when 'hop' then # @dispatch cursor: ruh.hop #; @bell() # XX buffer.transpose?
      when 'blk' then console.log "Stub #{str ruh}"
      when 'det' then @dispatchTo app, receive: ruh.det
      when 'act' then switch ruh.act
        when 'clr' then @dispatch {'clear'}
        when 'bel' then @bell()
        when 'nex'
          # @dispatch state: input: "" hmm
          @dispatch {'line'}
          # if @state.input # pipe through somehow?
          #   @dispatch state: historyAdd: @state.input
      #   else throw "Unknown "+(JSON.stringify ruh)
      else v = Object.keys(ruh); console.log v, ruh[v[0]]

  join: (app,state)->
    # if state[app]?
    #   return @print '# already-joined: '+app
    @choose app
    urb.bind "/drum", {app,responseKey:"/"}, (err,d)=>
      if err then console.log err
      else if d.data then @peer d.data, app
      
  cycle: (app, state)->
    apps = Object.keys state
    if apps.length < 2 then return
    @choose apps[1 + apps.indexOf app] ? apps[0]
  
  part: (app,state)->
    unless state[app]?
      return @print '# not-joined: '+app
    urb.drop "/drum", {app, responseKey: "/"}
    @cycle app, state
    @dispatchTo app, {"part"}

  sendAction: (app, share, data)->  # handle join/part ^V prompt
    if app
      urb.send data, {app,mark:'sole-action'}, (e,res)=>
        if res.status isnt 200
          @dispatch state: error: res.data.mess
    else if data is 'ret'
      app = /^[a-z-]+$/.exec(share[""].buf.slice(1))
      unless app? and app[0]?
        return @bell()
      else switch share[""].buf[0]
        when '+' then @doEdit app, buffer, set: ""; @join app[0]
        when '-' then @doEdit app, share, set: ""; @part app[0]
        else @bell()

  doEdit: (app, {share, cursor}, ted)->
    det = share.transmit ted
    cursor = share.transpose ted, cursor
    @dispatchTo app, edit: {share,cursor}
    @sendAction app, share, {det}
  
  sendKyev: (mod, key, app)->
    urb.send {mod,key}, {app,mark:'dill-belt'}
    
  eatKyev: (mod, key, app, {share,input,cursor,yank})-> # XX minimize state usage
    buffer = {share,cursor}
    # if true then return @sendKyev mod, key, app
    switch mod.sort().join '-'
      when '', 'shift'
        if key.str
          @doEdit app, buffer, ins: cha: key.str, at: cursor
          @dispatchTo app, cursor: cursor+1
        switch key.act
          when 'entr' then @sendAction app, share, 'ret'
          when 'up' then @dispatchTo app, {'historyPrevious'}
          when 'down' then @dispatchTo app, {'historyNext'}
          # when 'up'
          #   history = state.history.slice(); offset = state.offset
          #   if history[offset] == undefined
          #     return
          #   [input, history[offset]] = [history[offset], input]
          #   offset++
          #   @doEdit app, buffer, set: input
          #   @dispatch state: {offset, history, cursor: input.length}
          # when 'down'
          #   history = state.history.slice(); offset = state.offset
          #   offset--
          #   if history[offset] == undefined
          #     return
          #   [input, history[offset]] = [history[offset], input]
          #   @doEdit app, buffer, set: input
          #   @dispatch state: {offset, history, cursor: input.length}
          when 'left' then if cursor > 0 
            @dispatchTo app, cursor: cursor-1
          when 'right' then if cursor < input.length
            @dispatchTo app, cursor: cursor+1
          when 'baxp' then if cursor > 0
            @doEdit app, buffer, del: cursor-1
          #else (if key.act then console.log key.act)
      when 'ctrl' then switch key.str || key.act
        when 'a','left'  then @dispatchTo app, cursor: 0
        when 'e','right' then @dispatchTo app, cursor: input.length
        when 'l' then @dispatch {'clear'}
        when 'entr' then @bell()
        when 'w' then @eatKyev ['alt'], act:'baxp'
        when 'p' then @eatKyev [], act: 'up'
        when 'n' then @eatKyev [], act: 'down'
        when 'b' then @eatKyev [], act: 'left'
        when 'f' then @eatKyev [], act: 'right'
        when 'g' then @bell()
        when 'x' then @cycle app, state
        when 'v' then @dispatch app:''
        when 't'
          if cursor is 0 or input.length < 2
            return @bell()
          if cursor < input.length
            cursor++
          @doEdit app, buffer, [{del:cursor-1},ins:{at:cursor-2,cha:input[cursor-1]}]
          @dispatchTo app, {cursor}
        when 'u' 
          @dispatch yank: input.slice(0,cursor)
          @doEdit app, buffer, (del:cursor - n for n in [1..cursor])
        when 'k'
          @dispatch yank: input.slice(cursor)
          @doEdit app, buffer, (del:cursor for _ in [cursor...input.length])
        when 'y'
          @doEdit app, buffer, (ins: {cha, at: cursor + n} for cha,n in yank ? '')
        else console.log mod, str key
      when 'alt' then switch key.str || key.act
        when 'f','right'
          rest = input.slice(cursor)
          rest = rest.match(/\W*\w*/)[0] # XX unicode
          @dispatchTo app, cursor: cursor + rest.length
        when 'b','left'
          prev = input.slice(0,cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @dispatchTo app, cursor: cursor - prev.length
        when 'baxp'
          prev = input.slice(0,cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @dispatch yank: prev
          @doEdit app, buffer, (del: cursor-1 - n for _,n in prev)
      else console.log mod, str key
