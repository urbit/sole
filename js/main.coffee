[recl,rele]                    = [React.createClass, React.createElement]
{div, u, pre, span}            = React.DOM
TreeStore                      = window.tree.util.store
{registerComponent}            = window.tree.util.actions

{createStore}                  = Redux
{Provider, connect}            = ReactRedux

str = JSON.stringify
Reducer = require "./reducer.coffee"
Actions = require "./actions.coffee"

stateToProps = ({yank,rows,app,state})->
  {prompt,buffer:{share,cursor},history,error} = state[app]
  if app is ''
    prompt = (k for k,v of state when k isnt '').join(', ') + '# '  
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
      store = createStore Reducer, window.__REDUX_DEVTOOLS_EXTENSION__()
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
