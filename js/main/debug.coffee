if DEBUG
  console.log '--- DEBUG MODE ---'

  _date = +new Date()
  
  $ ->
    console.log "jQuery's 'ready' event fired: #{ +new Date() - _date } ms"
    
  $w.on 'load', ->
    console.log "'load' event fired: #{ +new Date() - _date } ms"
