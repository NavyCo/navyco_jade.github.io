$ ->
  urlContains = (string) ->
    location.pathname.indexOf(string) isnt -1

    # set page title
    if xhr?.getResponseHeader 'X-PJAX-Title'
      document.title = xhr.getResponseHeader 'X-PJAX-Title'
    
    # top page
