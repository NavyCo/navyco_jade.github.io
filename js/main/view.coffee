NProgress.configure
  trickleRate: 0.2
  trickleSpeed: 265
  showSpinner: false

# location.origin polyfill
if not location.origin?
  port = ''
  if location.port
    port = ":#{ location.port }"
  location.origin = location.protocol + "//" + location.hostname + port

AppView = Backbone.View.extend
  el: '#container'
  
  events:
    'click a:not([target])': 'render'
  
  render: (e) ->
    e.preventDefault()
    
    content.hide ->
      nextUrl = $(e.currentTarget)
        .attr 'href'
        .replace location.origin, ''
      router.navigate nextUrl, {trigger: true}
      if router.prev is Backbone.history.fragment
        content.show()
      scrollTo 0, 0

ContentView = Backbone.View.extend
  el: 'main'
  
  hide: (callback) ->
    NProgress
      .set 0.0
      .start()
    this.$el.fadeTo 8, 0.010, ->
      callback() if callback
    
  show: (callback) ->
    NProgress.done()
    this.$el.fadeTo 80, 1
    router.prev = Backbone.history.fragment
    callback() if callback
  
  render: (page, callback) ->
    this.$el.load "#{ page } #content", callback

TabView = Backbone.View.extend
  el: '#tabs > a'
  
  activate: ->
    this.$el
      .filter '.active'
      .removeClass 'active'
    for page, i in ['about', 'project']
      if Backbone.history.fragment.indexOf(page) isnt -1
        this.$el.eq(i+1).addClass 'active'
        break
      if i is 1
        this.$el.eq(0).addClass 'active'

HomeView = Backbone.View.extend
  #TODO: separate logics to model!

  el: '.top'
  
  reset: ->
    # Open the ribbon
    $('#scroll-down').fadeOut 80, ->
      $(this).remove()
    $('#left-ribbon, #right-ribbon').transition {
      width: 0
    }, 250, ->
      $('#ribbon').remove()
    
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
      .lazyload
        effect : 'fadeIn'
        threshold : $w.height() * 0.25
        skip_invisible: false
        placeholder: '/img/transparent.gif'
    
    $ '#logo'
    .delay 200
    .transition {
      backgroundPosition: '0px 0px'
    }, 500

ProjectThumbnailView = Backbone.View.extend
  el: 'img[data-original]'
  
  render: ->
    this.$el
    .removeAttr 'src'
    .lazyload
      effect : 'fadeIn'
      threshold : $w.height() * 0.15
      placeholder: '/img/transparent.gif'

ProjectImageView = Backbone.View.extend
  el: 'img[data-original]'
  
  render: ->
    this.$el
      .removeAttr 'src'
      .lazyload
        effect: 'fadeIn'
        threshold: $w.height() * 0.5
        effect_speed:
          start: ->
            $this = $ this
            if $this.is '.project-image:eq(0)'
              $this.finish()
              content.show()
          always: ->
            # 「'.image-wrapper' の子孫である」要素に限定せずに .unwrap() すると、
            # ブラウザバックのたびに親要素を一つずつ消していってしまう
            $ '.image-wrapper'
              .find this
              .unwrap()
