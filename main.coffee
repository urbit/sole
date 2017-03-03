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
      
  buffer = (state = (new Share ""), {type,payload})->
    switch type
      when "edit"
        {buf, ven, lef} = state.abet()
        state = new Share buf, ven, leg
        state.transmit payload
        state
      when "choose"
        state # implicit in byApp
      else state
      
  prompt = (state = "X", {type, payload})->
    switch type
      when "prompt" then payload
      else state
  cursor = (state = 0, {type, payload})->
    switch type
      when "state.cursor" then payload
      when "line" then 0
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
    byApp combineReducers {prompt,buffer,cursor,history,error}}

getPrompt = (app, state)->
  if app is ''
    (k for k,v of state).join(', ') + '# '
  else
    state[app].prompt
    
getInput = ({buffer,history})->
  if history.offset >= 0
    history.log[history.offset] # editable mb?
  else buffer.buf

noPad = padding: 0

Prompt = ({prompt,cursor,input})->
  cur =  cursor - prompt.length
  buf =  input + " "
  pre {style:noPad}, prompt,
    span {style: background: 'lightgray'},
      buf.slice(0,cur), (u {}, buf[cur] ? " "), buf.slice(cur + 1)
      # "⧖ " history.offset

Matr = ({rows,app,prompt,input,cursor}) ->
  div {},
    for lin,key in rows
      pre {key,style:noPad}, lin, " "
    rele Prompt, {prompt,input,cursor,key: "prompt"}

Sole = connect((a)->a) ({state,rows,app})->
  {buffer, cursor, history, error} = state[app]
  input = getInput {buffer, history}
  prompt = getPrompt app, state
  (div {},
     (div {id:"err"},error)
     (rele Matr, {rows,app,prompt,input,cursor})
  )

IO = connect(((s)->s),(dispatch)-> Actions: Actions dispatch) recl
  render: -> div {}
  componentWillUnmount: -> Mousetrap.handleKey = @_defaultHandleKey
  componentDidMount: ->
    @_defaultHandleKey = Mousetrap.handleKey 
    Mousetrap.handleKey = (char, mod, e)=>
      {mod, key} = toKyev {char, mod, type:e.type}
      if key
        e.preventDefault()
        @props.Actions.eatKyev mod, key, @props.app, @props.state[@props.app]
        
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
  sync: (ted,app)->
    if app is @state.app
      b = buffer[app]
      @dispatch state: cursor: b.transpose ted, @state.cursor
    
  peer: (ruh,app) ->
    if ruh.map then return ruh.map (rul)=> @peer rul, app
    switch Object.keys(ruh)[0]
      when 'out' then @print ruh.out
      when 'txt' then @print ruh.txt
      when 'tan' then ruh.tan.trim().split("\n").map @print
      when 'pro' then @dispatchTo app, prompt: ruh.pro.cad
      when 'pom' then @dispatchTo app, prompt: _.map ruh.pom, ({text})->text
      when 'hop' then @dispatch "state.cursor": ruh.hop #; @bell() # XX buffer.transpose?
      when 'blk' then console.log "Stub #{str ruh}"
      when 'det' then buffer[app].receive ruh.det; @sync ruh.det.ted, app
      when 'act' then switch ruh.act
        when 'clr' then @dispatch {'clear'}
        when 'bel' then @bell()
        when 'nex'
          # @dispatch state: input: "" hmm
          @dispatch {'line'}
          if @state.input
            @dispatch state: historyAdd: @state.input
      #   else throw "Unknown "+(JSON.stringify ruh)
      else v = Object.keys(ruh); console.log v, ruh[v[0]]

  join: (app)->
#     if @state[app]?
#       return @print '# already-joined: '+app
    @choose app
    urb.bind "/drum", {app,responseKey:"/"}, (err,d)=>
      if err then console.log err
      else if d.data then @peer d.data, app
      
  cycle: ()->
    apps = Object.keys @state
    if apps.length < 2 then return
    @choose apps[1 + apps.indexOf @state.app] ? apps[0]
  
  part: (app)->
    unless @state[app]?
      return @print '# not-joined: '+app
    urb.drop "/drum", {app, responseKey: "/"}
    if app is @state.app then @cycle()
    @dispatchTo app, {"part"}
  
  componentDidMount: ->
    @join @state.app

  sendAction: (data)->  # handle join/part ^V prompt
    {app} = @state
    if app
      urb.send data, {app,mark:'sole-action'}, (e,res)=>
        if res.status isnt 200
          @dispatch state: error: res.data.mess
    else if data is 'ret'
      app = /^[a-z-]+$/.exec(buffer[""].buf.slice(1))
      unless app? and app[0]?
        return @bell()
      else switch buffer[""].buf[0]
        when '+' then @dispatch edit: set: ""; @join app[0]
        when '-' then @dispatch edit: set: ""; @part app[0]
        else @bell()

  doEdit: (ted, app)->
    @dispatchTo app, edit: ted
    det = buffer[app].transmit ted
    @sync ted, app
    @sendAction {det}
  
  sendKyev: (mod, key, app)->
    urb.send {mod,key}, {app,mark:'dill-belt'}
    
  eatKyev: (mod, key, app, state)-> # XX minimize state usage
    if true then return @sendKyev mod, key, app
    switch mod.sort().join '-'
      when '', 'shift'
        if key.str
          @dispatch edit: ins: cha: key.str, at: state.cursor
          @dispatch state: cursor: state.cursor+1
        switch key.act
          when 'entr' then @sendAction 'ret'
          when 'up' then dispatch {'historyPrevious'}
          when 'down' then dispatch {'historyNext'}
          # when 'up'
          #   history = state.history.slice(); offset = state.offset
          #   if history[offset] == undefined
          #     return
          #   [input, history[offset]] = [history[offset], state.input]
          #   offset++
          #   @dispatch edit: set: input
          #   @dispatch state: {offset, history, cursor: input.length}
          # when 'down'
          #   history = state.history.slice(); offset = state.offset
          #   offset--
          #   if history[offset] == undefined
          #     return
          #   [input, history[offset]] = [history[offset], state.input]
          #   @dispatch edit: set: input
          #   @dispatch state: {offset, history, cursor: input.length}
          when 'left' then if state.cursor > 0 
            @dispatch state: cursor: state.cursor-1
          when 'right' then if state.cursor < state.input.length
            @dispatch state: cursor: state.cursor+1
          when 'baxp' then if state.cursor > 0
            @dispatch edit: del: state.cursor-1
          #else (if key.act then console.log key.act)
      when 'ctrl' then switch key.str || key.act
        when 'a','left'  then @dispatch state: cursor: 0
        when 'e','right' then @dispatch state: cursor: state.input.length
        when 'l' then @dispatch {'clear'}
        when 'entr' then @bell()
        when 'w' then @eatKyev ['alt'], act:'baxp'
        when 'p' then @eatKyev [], act: 'up'
        when 'n' then @eatKyev [], act: 'down'
        when 'b' then @eatKyev [], act: 'left'
        when 'f' then @eatKyev [], act: 'right'
        when 'g' then @bell()
        when 'x' then @cycle()
        when 'v' then @dispatch app:''
        when 't'
          if state.cursor is 0 or state.input.length < 2
            return @bell()
          cursor = state.cursor
          if cursor < state.input.length
            cursor++
          @dispatch edit: [{del:cursor-1},ins:{at:cursor-2,cha:state.input[cursor-1]}]
          @dispatch state: {cursor}
        when 'u' 
          @dispatch state: yank: state.input.slice(0,state.cursor)
          @dispatch edit: (del:state.cursor - n for n in [1..state.cursor])
        when 'k'
          @dispatch state: yank: state.input.slice(state.cursor)
          @dispatch edit: (del:state.cursor for _ in [state.cursor...state.input.length])
        when 'y'
          @dispatch edit: (ins: {cha, at: state.cursor + n} for cha,n in state.yank ? '')
        else console.log mod, str key
      when 'alt' then switch key.str || key.act
        when 'f','right'
          rest = state.input.slice(state.cursor)
          rest = rest.match(/\W*\w*/)[0] # XX unicode
          @dispatch state: cursor: state.cursor + rest.length
        when 'b','left'
          prev = state.input.slice(0,state.cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @dispatch state: cursor: state.cursor - prev.length
        when 'baxp'
          prev = state.input.slice(0,state.cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @dispatch state: yank: prev
          @dispatch edit: (del: state.cursor-1 - n for _,n in prev)
      else console.log mod, str key
