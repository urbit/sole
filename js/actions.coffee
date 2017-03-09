str = JSON.stringify

Persistence =
  listen: (app,cb)->
    urb.bind "/sole/"+app, {app:"drumming",responseKey:"/"+app}, (err,d)=>
      if err then console.log err
      else if d.data then cb d.data
      
  drop: (app)->
    urb.drop "/sole/"+app, {app:"drumming", responseKey: "/"+app}

  sendAct: (app,data,_,cbErr)->
    urb.send data, {app:"drumming",mark:'sole-action', responseKey:"/"+app}, (e,res)=>
      # if e then cbErr e
      if res.status isnt 200
        cbErr res.data
        
  sendKey: (app, {mod, key})->
    urb.send {mod,key}, {app:"drumming",mark:'dill-belt', responseKey:"/"+app}

module.exports =
  flash: ($el, background)->
    $el.css {background}
    if background
      setTimeout (=> @flash $el,''), 50
  bell: -> @flash ($ 'body'), 'black'
    
  getState: (app)-> # XX this seems vaguely smelly
    {drum,yank,rows,state} = @_getState()
    {buffer:{share,cursor},history,error} = state[app]
    input = 
      share.buf
#       if history.offset >= 0
#         history.log[history.offset] # editable mb?
#       else share.buf
    apps = (k for k of state when k isnt "")
    nextApp = apps[1 + apps.indexOf app] ? apps[0]
    {yank,rows,app,nextApp,state,prompt,share,cursor,input,error}

  dispatch: (action)->
    type = (k for k of action).join " "
    @_dispatch {type,payload:action[type]}

  dispatchTo: (app,action)->
    type = (k for k of action).join " "
    @_dispatch {type,app,payload:action[type]}

  choose: (app)-> @dispatchTo app, {"choose"}
  
  print: (row)-> @dispatch {row}
    
  peer: (ruh,app) ->
    if ruh.map then return ruh.map (rul)=> @peer rul, app
    switch Object.keys(ruh)[0]
      when 'out' then @print ruh.out
      when 'txt' then @print ruh.txt
      when 'tan' then ruh.tan.trim().split("\n").map (s)=> @print s
      when 'pro' then @dispatchTo app, prompt: ruh.pro.cad
      when 'pom'
        # XX actually separate app contents from prompt
        if ruh.pom.length
          @dispatchTo app, prompt: ruh.pom[0].text # _.map ruh.pom, ({text})->text 
      when 'hop' then # @dispatch cursor: ruh.hop #; @bell() # XX buffer.transpose?
      when 'blk' then console.log "Stub #{str ruh}"
      when 'det' then @dispatchTo app, receive: ruh.det
      when 'act' then switch ruh.act
        when 'clr' then @dispatch {'clear'}
        when 'bel' then @bell()
        when 'nex'
          @dispatch {'line'}
#           {input} = @getState app
#           if input then @dispatchTo app, historyAdd: input
      #   else throw "Unknown "+(JSON.stringify ruh)
      else v = Object.keys(ruh); console.log v, ruh[v[0]]

  join: (app,state)-> (@_dispatch)=> @_join app, state # XX bind new object?
  _join: (app,state)->
    # if state[app]?
    #   return @print '# already-joined: '+app
    @choose app
    Persistence.listen app, (data)=> @peer data, app
  
  part: (app,state)->
    # unless state[app]?
    #   return @print '# not-joined: '+app
    Persistence.drop app
    @cycle app, state
    @dispatchTo app, {"part"}

  sendAction: (app, share, data)->  # handle join/part ^V prompt
    if app
      Persistence.sendAct app, data, null, (err)=>
        @dispatch error: err.mess
    else if data is 'ret'
      app = /^[a-z-]+$/.exec(share.buf.slice(1))
      unless app? and app[0]?
        return @bell()
      else switch share.buf[0]
        when '+' then @doEdit '', {share}, set: ""; @_join app[0]
        when '-' then @doEdit '', {share}, set: ""; @part app[0]
        else @bell()

  doEdit: (app, {share, cursor}, ted)->
    det = share.transmit ted # XX fit this into redux model somehow
    cursor = share.transpose ted, cursor
    @dispatchTo app, edit: {share,cursor}
    @sendAction app, share, {det}
    
  eatKyev: (mod, key)-> (@_dispatch, @_getState)=> # XX bind new object?
    {drum,app} = @_getState()
#     if drum then app = ""
    {yank,rows,app,nextApp,state,share,cursor,input} = @getState app
    buffer = {share,cursor}

    # if true then return Persistence.sendKey app, {mod, key}
    switch mod.sort().join '-'
      when '', 'shift'
        if key.str
          @doEdit app, buffer, ins: cha: key.str, at: cursor
          @dispatchTo app, cursor: cursor+1
        switch key.act
          when 'entr' then @sendAction app, share, 'ret'
#           when 'up' then @dispatchTo app, {'historyPrevious'}
#           when 'down' then @dispatchTo app, {'historyNext'}
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
#         when 'p' then @eatKyev [], act: 'up'
#         when 'n' then @eatKyev [], act: 'down'
        when 'b' then @eatKyev [], act: 'left'
        when 'f' then @eatKyev [], act: 'right'
        when 'g' then @bell()
        when 'x' then Persistence.sendKey app, {mod, key} #@choose nextApp
#         when 'v' then @dispatch {"toggleDrum"}
        when 't'
          if cursor is 0 or input.length < 2
            return @bell()
          if cursor < input.length
            cursor++
          @doEdit app, buffer, [{del:cursor-1},ins:{at:cursor-2,cha:input[cursor-1]}]
          @dispatchTo app, {cursor}
        when 'u' 
#           @dispatch yank: input.slice(0,cursor)
          @doEdit app, buffer, (del:cursor - n for n in [1..cursor])
        when 'k'
#           @dispatch yank: input.slice(cursor)
          @doEdit app, buffer, (del:cursor for _ in [cursor...input.length])
#         when 'y'
#           @doEdit app, buffer, (ins: {cha, at: cursor + n} for cha,n in yank ? '')
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
#           @dispatch yank: prev
          @doEdit app, buffer, (del: cursor-1 - n for _,n in prev)
      else console.log mod, str key
