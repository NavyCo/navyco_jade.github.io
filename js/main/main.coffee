container = content = router = null

$ ->
  router = new Router()

  container = new AppView {model: new Page()}
  content = new ContentView()
  prevNextButton = new PrevNextButtonView()
  
  # start
  Backbone.history.start
    pushState: true
    root: if DEBUG then '/debug/' else '/'
    
  $('.intersection .point > div').css
    visibility: 'visible'

  #TODO: migrate this section to view!
  resetContent = ->
    container.refresh()
  
  router.on 'route', (route) ->
    resetContent()
  resetContent()
