container = content = menuTabs = router = null

$ ->
  if DEBUG
    router = new Router
      routes:
        'debug/': 'index'
        'debug/index.html': 'index'
        'debug/about.html': 'about'
        'debug/projects.html': 'projects'
        'debug/projects/:name': 'project-single'
  else
    router = new Router()

  container = new AppView {model: router}
  content = new ContentView()
  menuTabs = new TabView()
  verticalLine = new VerticalLineView()
  labelLink = new LabelLinkView()
  
  # start
  if Modernizr.history
    Backbone.history.start {pushState: true}
    
  $('.intersection .point > div').css
    visibility: 'visible'

  #TODO: migrate this section to view!
  resetContent = ->

    menuTabs.activate()
    
    $('.intersection .point > div').fadeIn()
    
    # top page
    if location.href.indexOf('projects') is -1 and
    location.href.indexOf('about') is -1
      #$('#vertical-line').transit
        #height: $('.header-line').position().top
      verticalLine.hide()
      $('.intersection').fadeOut 42
    
    else
      for basename of routerData
        if location.href.indexOf("#{ basename }.") isnt -1
          pageData = routerData[basename]
          if pageData.title
            $('#first-location').show()
            $('#first-location .label').text pageData.title
            $('#project-title, #project-info').fadeOut 42
            
            verticalLine.extendToFirst()
            $('#first-point').css
              top: "#{ $('#first-location').height() * 0.5 }px"
              
            $('#first-location a').attr 'href', _href

          if pageData.proj_title
            $('#first-location .label').text 'プロジェクト一覧'
            $('.intersection').show()
            $('#project-title > .label').text pageData.proj_title
            $('#project-info .time').text pageData.time
            $('#project-info .roles').text pageData.role.join(' / ')
            
            _href = $ '#first-location a:eq(0)'
              .attr('href')
              .replace /\/[^\/]+?.html/, '/projects.html'
            $('#first-location a').attr 'href', _href
        
            $('#vertical-line').transit
              height: $('#project-info').centerHeight() + 'px'
            
            $('#first-point').css
              top: "#{ $('#first-location').height() * 0.5 }px" 
            $('#project-title-point').css
              top: "#{ $('#project-title').height() * 0.5 }px" 
            $('#project-info-point').css
              top: "#{ $('#project-info').height() * 0.5 }px"

          break
  
  router.on 'route', ->
    resetContent()
  resetContent()
