container = content = menuTabs = router = null

$ ->
  router = new Router()
  
  container = new AppView {model: router}
  content = new ContentView()
  menuTabs = new TabView()
  
  # start
  if Modernizr.history
    Backbone.history.start {pushState: true}
    
  #TODO: migrate this section to view!
  resetContent = ->

    menuTabs.activate()
    
    if location.href.indexOf('projects') is -1 and
    location.href.indexOf('about') is -1
      $('#vertical-line').transit
        height: $('.header-line').position().top
      $('#first-location, #project-title, #project-info').hide()
    
    else
      for basename of routerData
        if location.href.indexOf("#{ basename }.") isnt -1
          pageData = routerData[basename]
          if pageData.title
            $('#first-location').show().text pageData.title
            $('#project-title, #project-info').hide()

            $('#vertical-line').transit
              height: Math.round(
                $('#first-location').position().top +
                $('#first-location').height() * 0.5
              )

          if pageData.proj_title
            $('#first-location').show().text 'プロジェクト一覧'
            $('#project-title, #project-info').show()
            $('#project-title > span').text pageData.proj_title
            $('#project-info .time').text pageData.time
            $('#project-info .roles').text pageData.role.join(' / ')
        
            $('#vertical-line').transit {
              height: Math.round(
                $('#first-location').position().top +
                $('#first-location').height() * 0.5
              )
            }, ->
              $(this).transit
                height: Math.round($('#project-info').position().top)

          break
  
  router.on 'route', ->
    resetContent()
  resetContent()
    
