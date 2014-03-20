NProgress.configure
  trickleRate: 0.2
  trickleSpeed: 265
  showSpinner: false

AppView = Backbone.View.extend
  el: '#container'
  events:
    'click a:not([target])': 'setInternalLink'
  
  initialize: ->
    @menuTabs = new TabView()
    @verticalNav = new VerticalNavView()
    @model.on 'change:category', (model, value) =>
      @menuTabs.activate value
      @verticalNav.setLink value
    @model.on 'change:basename', (model, value) =>
      @verticalNav.render value
    
  setInternalLink: (e) ->
    e.preventDefault()
    
    content.hide ->
      nextUrl = $ e.currentTarget
        .attr 'href'
        .replace location.origin, ''
      router.navigate nextUrl, {trigger: true}
      if router.prev is Backbone.history.fragment
        content.show()
      scrollTo 0, 0

  refresh: ->
    @model.categorize()

TabView = Backbone.View.extend
  el: '#tabs > a'
  
  activate: (category) ->
    @$el
      .filter '.active'
      .removeClass 'active'
      .end()
      .filter "[data-category=#{ category }]"
      .addClass 'active'

VerticalNavView = Backbone.View.extend
  el: 'header div.intersection'
  
  initialize: ->
    @labels = new NavLabelView()
    @points = new NavPointView()
    @line = new VerticalLineView()
    
  hide: ->
    @line.hide()
    @$el.fadeOut 42
  
  setLink: (category) ->
    $link = @$el.find 'a'
    _backToCategory = $link
      .attr 'href'
      .replace /\/[^\/]+?\.html/, "/#{ category }.html"
    $link.attr 'href', _backToCategory
  
  render: (basename) ->
    @points.show()
    if basename is 'index'
      @hide()
    else
      pageData = routerData[container.model.get('basename')]
      if pageData.title
        $('#first-location').show()
        $('#first-location .label').text pageData.title
        $('#project-title, #project-info').fadeOut 42
        
        @line.extendToFirst()
        $('#first-point').css
          top: "#{ $('#first-location').height() * 0.5 }px"
          
      if pageData.proj_title
        $('#first-location .label').text 'プロジェクト一覧'
        $('.intersection').show()
        $('#project-title > .label').text pageData.proj_title
        $('#project-info .time').text pageData.time
        $('#project-info .roles').text pageData.role.join(' / ')
        
        @line.extendToProject()
        
        $('#first-point').css
          top: "#{ $('#first-location').height() * 0.5 }px"
        $('#project-title-point').css
          top: "#{ $('#project-title').height() * 0.5 }px"
        $('#project-info-point').css
          top: "#{ $('#project-info').height() * 0.5 }px"
    

NavPointView = Backbone.View.extend
  el: 'div.intersection .point > div'
  
  hide: ->
    $first = @$el.eq(0)

  show: ->
    @$el.fadeIn()

NavLabelView = Backbone.View.extend
  el: 'div.intersection > .label'
  
VerticalLineView = Backbone.View.extend
  el: '#vertical-line'
  
  hide: ->
    @$el.transit
      height: '0'

  extendToFirst: ->
    @$el.transit
      height: $('#first-location').centerHeight() + 'px'

  extendToProject: ->
    @$el.transit
      height: $('#project-info').centerHeight() + 'px'

PrevNextButtonView = Backbone.View.extend
  el: '#prev-project-button, #next-project-button'
  
  initialize: ->
    $w.on 'resize', =>
      @render()
  
  render: ->
    if Modernizr.mq 'only screen and (min-width: 1280px)'
      #console.log @$el
      return #tmp

ContentView = Backbone.View.extend
  el: 'main'
  
  hide: (callback) ->
    NProgress
      .set 0.0
      .start()
    @$el.fadeTo 8, 0.010, ->
      callback() if callback
    
  show: (callback) ->
    NProgress.done()
    @$el.fadeTo 80, 1
    router.prev = Backbone.history.fragment
    callback() if callback
  
  render: (page, callback) ->
    if DEBUG
      page = "/debug#{ page }"
    @$el.load "#{ page } #content", callback

HomeView = Backbone.View.extend
  #TODO: separate logics to model!

  el: '.top'
  
  reset: ->
    # Open the ribbon
    ###
    $('#scroll-down').fadeOut 80, ->
      $(this).remove()
    $('#left-ribbon, #right-ribbon').transition {
      width: 0
    }, 250, ->
      $('#ribbon').remove()
    ###
    
    $('.top .inner').transition {
      paddingTop: '0'
    }, 400
    
    $('.wide-image').css 'width', '100%'
    
    $ '.featured-works'
      .css 'visibility', 'visible'
      .fadeTo 750, 1
    
  render: ->
    self = this
    
    $w.one 'scoll', self.reset()
    $('#scroll-down').on 'click', ->
      $('html,body').animate {
        scrollTop: "#{ $('header').height() }px"
      }, 400
      self.reset()
    
    $ 'img[data-original]'
      .removeAttr 'src'
      ._enableWebP()
      .lazyload
        effect : 'fadeIn'
        threshold : $w.height() * 0.25
        skip_invisible: false
        placeholder: '/img/transparent.gif'
    
    $ '#logo'
      .delay 200
      .transition {backgroundPosition: '0px 0px'}, 500

ProjectThumbnailView = Backbone.View.extend
  el: 'img[data-original]'
  
  render: ->
    this.$el
      .removeAttr 'src'
      ._enableWebP()
      .lazyload
        effect : 'fadeIn'
        threshold : $w.height() * 0.15
        placeholder: '/img/transparent.gif'

ProjectImageView = Backbone.View.extend
  el: 'img[data-original]'
  
  render: ->
    _hasVideo = $('.video-wrapper').length > 0
    content.show() if _hasVideo
    
    this.$el
      .removeAttr 'src'
      ._enableWebP()
      .lazyload
        effect: 'fadeIn'
        threshold: $w.height() * 0.5
        placeholder: '/img/transparent.gif'
        effect_speed:
          start: ->
            $this = $ this
            if not _hasVideo and $this.is '.project-image:eq(0)'
              $this.finish()
              content.show()
          always: ->
            # 「'.image-wrapper' の子孫である」要素に限定せずに .unwrap() すると、
            # ブラウザバックのたびに親要素を一つずつ消していってしまう
            $ '.image-wrapper'
              .find this
              .unwrap()

ShowMoreCommitsView = Backbone.View.extend
  el: '#show-more-commits span'
  events:
    'click': 'show'
  show: ->
    this.$el.remove()
    $('#commits-rest').fadeIn()
  
