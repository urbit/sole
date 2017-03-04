[recl,rele]                    = [React.createClass, React.createElement]
{div, u, pre, span}            = React.DOM
TreeStore                      = window.tree.util.store
{registerComponent}            = window.tree.util.actions

{createStore, applyMiddleware} = Redux
{Provider, connect}            = ReactRedux
thunk                          = ReduxThunk.default

str = JSON.stringify
Reducer = require "./reducer.coffee"
Actions = require "./actions.coffee"

noPad = padding: 0

stateToProps = ({,app,state})->
  {prompt,buffer:{share,cursor},history} = state[app]
  if app is ''
    prompt = (k for k,v of state when k isnt '').join(', ') + '# '  
  input = 
    if history.offset >= 0
      history.log[history.offset] # editable mb?
    else share.buf
  {prompt,cursor,offset:history.offset,input}

Prompt = connect(stateToProps) ({prompt,cursor,offset,input})->
  cur =  cursor #- prompt.length
  buf =  input + " "
  pre {style:noPad}, prompt,
    span {style: background: 'lightgray'},
      buf[...cur], (u {}, buf[cur] ? " "), buf[cur+1 ..]
    (" ⧖" + offset) if offset >= 0

Matr = connect((s)->s) ({rows}) ->
  div {},
    for lin,key in rows
      pre {key,style:noPad}, lin, " "
    rele Prompt

Sole = connect(({app,state})->state[app]) ({error})->
  (div {},
     (div {id:"err"},error)
     (rele Matr)
  )

IO = connect() recl
  render: -> div {}
  componentWillUnmount: -> Mousetrap.handleKey = @_defaultHandleKey
  componentDidMount: ->
    @_defaultHandleKey = Mousetrap.handleKey 
    Mousetrap.handleKey = (char, mod, e)=>
      {mod, key} = toKyev {char, mod, type:e.type}
      if key
        e.preventDefault()
        @props.dispatch Actions.eatKyev mod, key
        
setTimeout -> # XX
  TreeStore.dispatch registerComponent "sole", recl
    getInitialState: ->
      store = createStore Reducer,
        (window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || (s)->s) applyMiddleware(thunk)
      store.dispatch Actions.join @props["data-app"]
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
