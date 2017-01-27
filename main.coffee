[recl,rele] = [React.createClass, React.createElement]
{div, u, pre, span} = React.DOM
TreeStore = window.tree.util.store
{registerComponent} = window.tree.util.actions

str = JSON.stringify
Share = require "./share.coffee"

buffer = "": new Share "" # XX global


Prompt = recl
  displayName: "Prompt"
  render: ->
    pro = @props.prompt[@props.app] ? "X"
    cur =  @props.cursor
    buf =  @props.input + " "
    pre {}, @props.app, pro,
      span {style: background: 'lightgray'},
        buf.slice(0,cur), (u {}, buf[cur] ? " "), buf.slice(cur + 1)

Matr = recl
  displayName: "Matr"
  render: ->
    lines = @props.rows.map (lin,key)-> pre {key}, lin, " "
    lines.push rele Prompt,
      key: "prompt"
      app:   @props.app, 
      prompt: @props.prompt, 
      input:  @props.input, 
      cursor: @props.cursor
    div {}, lines

TreeStore.dispatch registerComponent "sole", recl
  displayName: "Sole"
  getInitialState: ->
    rows:[]
    app:@props["data-app"]
    prompt:{"": "# "}
    input:""
    cursor:0
    history:[]
    offset:0
    
    error:""

  render: ->
    (div {},
       (div {id:"err"},@state.error)
       (rele Matr, @state)
     )
  
  flash: ($el, background)->
    $el.css {background}
    if background
      setTimeout (=> @flash $el,''), 50
  bell: -> @flash ($ 'body'), 'black'
    
  choose: (app)->
    buffer[app] ?= new Share ""
    @updPrompt '', null
    @setState {app, cursor: 0, input: buffer[app].buf}
  
  print: (txt)-> @setState rows: [@state.rows..., txt]
  sync: (ted,app = @state.app)->
    if app is @state.app
      b = buffer[app]
      @setState input: b.buf, cursor: b.transpose ted, @state.cursor
  
  updPrompt: (app,pro) ->
    prompt = $.extend {}, @state.prompt
    if pro? then prompt[app] = pro else delete prompt[app]
    @setState {prompt}
    
  sysStatus: -> @updPrompt '', (
      [app,pro] = [@state.app, (k for k,v of @state.prompt when k isnt '')]
      if app is '' then (pro.join ', ')+'# ' else null
    )

  peer: (ruh,app = @state.app) ->
    if ruh.map then return ruh.map (rul)=> @peer rul, app
    mapr = @state
    switch Object.keys(ruh)[0]
      when 'txt' then @print ruh.txt
      when 'tan' then ruh.tan.split("\n").map @print
      when 'pro' then @updPrompt app, ruh.pro.cad
      when 'hop' then @setState cursor: ruh.hop; @bell() # XX buffer.transpose?
      when 'blk' then console.log "Stub #{str ruh}"
      when 'det' then buffer[app].receive ruh.det; @sync ruh.det.ted, app
      when 'act' then switch ruh.act
        when 'clr' then @setState rows:[]
        when 'bel' then @bell()
        when 'nex' then @setState
          input: ""
          cursor: 0
          history: 
            if !mapr.input then mapr.history
            else [mapr.input, mapr.history...]
          offset: 0
      #   else throw "Unknown "+(JSON.stringify ruh)
      else v = Object.keys(ruh); console.log v, ruh[v[0]]

  join: (app)->
    if @state.prompt[app]?
      return @print '# already-joined: '+app
    @choose app
    urb.bind "/sole", {app:@state.app,wire:"/"}, (err,d)=>
      if err then console.log err
      else if d.data then @peer d.data, app
      
  cycle: ()->
    apps = Object.keys @state.prompt
    if apps.length < 2 then return
    @choose apps[1 + apps.indexOf @state.app] ? apps[0]
  
  part: (app)->
    mapr = @state
    unless mapr.prompt[app]?
      return @print '# not-joined: '+app
    urb.drop "/sole", {app, wire: "/"}
    if app is mapr.app then @cycle()
    @updPrompt app, null
    @sysStatus()
  
  componentWillUnmount: -> @mousetrapStop()
  componentDidMount: ->
    @mousetrapInit()
    @join @state.app

  sendAction: (data)->  # handle join/part ^V prompt
    {app} = @state
    if app
      urb.send data, {app,mark:'sole-action'}, (e,res)=>
        if res.status isnt 200
          @setState error: res.data.mess
    else if data is 'ret'
      app = /^[a-z-]+$/.exec(buffer[""].buf.slice(1))
      unless app? and app[0]?
        return @bell()
      else switch buffer[""].buf[0]
        when '+' then @doEdit set: ""; @join app[0]
        when '-' then @doEdit set: ""; @part app[0]
        else @bell()

  doEdit: (ted)->
    det = buffer[@state.app].transmit ted
    @sync ted
    @sendAction {det}
  
  eatKyev: (mod, key)->
    mapr = @state
    switch mod.sort().join '-'
      when '', 'shift'
        if key.str
          @doEdit ins: cha: key.str, at: mapr.cursor
          @setState cursor: mapr.cursor+1
        switch key.act
          when 'entr' then @sendAction 'ret'
          when 'up'
            history = mapr.history.slice(); offset = mapr.offset
            if history[offset] == undefined
              return
            [input, history[offset]] = [history[offset], mapr.input]
            offset++
            @doEdit set: input
            @setState {offset, history, cursor: input.length}
          when 'down'
            history = mapr.history.slice(); offset = mapr.offset
            offset--
            if history[offset] == undefined
              return
            [input, history[offset]] = [history[offset], mapr.input]
            @doEdit set: input
            @setState {offset, history, cursor: input.length}
          when 'left' then if mapr.cursor > 0 
            @setState cursor: mapr.cursor-1
          when 'right' then if mapr.cursor < mapr.input.length
            @setState cursor: mapr.cursor+1
          when 'baxp' then if mapr.cursor > 0
            @doEdit del: mapr.cursor-1
          #else (if key.act then console.log key.act)
      when 'ctrl' then switch key.str || key.act
        when 'a','left'  then @setState cursor: 0
        when 'e','right' then @setState cursor: mapr.input.length
        when 'l' then @setState rows: []
        when 'entr' then @bell()
        when 'w' then @eatKyev ['alt'], act:'baxp'
        when 'p' then @eatKyev [], act: 'up'
        when 'n' then @eatKyev [], act: 'down'
        when 'b' then @eatKyev [], act: 'left'
        when 'f' then @eatKyev [], act: 'right'
        when 'g' then @bell()
        when 'x' then @cycle()
        when 'v'
          app = if mapr.app isnt '' then '' else @state.app
          @setState {app, cursor:0, input:buffer[app].buf}
          @sysStatus()
        when 't'
          if mapr.cursor is 0 or mapr.input.length < 2
            return @bell()
          cursor = mapr.cursor
          if cursor < mapr.input.length
            cursor++
          @doEdit [{del:cursor-1},ins:{at:cursor-2,cha:mapr.input[cursor-1]}]
          @setState {cursor}
        when 'u' 
          @yank = mapr.input.slice(0,mapr.cursor)
          @doEdit (del:mapr.cursor - n for n in [1..mapr.cursor])
        when 'k'
          @yank = mapr.input.slice(mapr.cursor)
          @doEdit (del:mapr.cursor for _ in [mapr.cursor...mapr.input.length])
        when 'y'
          @doEdit (ins: {cha, at: mapr.cursor + n} for cha,n in @yank ? '')
        else console.log mod, str key
      when 'alt' then switch key.str || key.act
        when 'f','right'
          rest = mapr.input.slice(mapr.cursor)
          rest = rest.match(/\W*\w*/)[0] # XX unicode
          @setState cursor: mapr.cursor + rest.length
        when 'b','left'
          prev = mapr.input.slice(0,mapr.cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @setState cursor: mapr.cursor - prev.length
        when 'baxp'
          prev = mapr.input.slice(0,mapr.cursor)
          prev = prev.split('').reverse().join('')  # XX
          prev = prev.match(/\W*\w*/)[0] # XX unicode
          @yank = prev
          @doEdit (del: mapr.cursor-1 - n for _,n in prev)
      else console.log mod, str key

  mousetrapStop: ->  Mousetrap.handleKey = @_defaultHandleKey
  mousetrapInit: ->
    @_defaultHandleKey = Mousetrap.handleKey 
    Mousetrap.handleKey = (char, mod, e)=>
      norm = {
        capslock:  'caps'
        pageup:    'pgup'
        pagedown:  'pgdn'
        backspace: 'baxp'
        enter:     'entr'
      }

      key = switch
        when char.length is 1
          if e.type is 'keypress'
            chac = char.charCodeAt(0)
            if chac < 32          # normalize ctrl keys
              char = String.fromCharCode chac | 96
            str: char
        when e.type is 'keydown'
          if char isnt 'space'
            act: norm[char] ? char
        when e.type is 'keyup' and norm[key] is 'caps'
          act: 'uncap'
      if !key then return
      if key.act and key.act in mod
        return
      e.preventDefault()
      @eatKyev mod, key
