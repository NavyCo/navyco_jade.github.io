Router = Backbone.Router.extend
  #ref: http://qiita.com/tekkoc/items/8e901196c3403c2194fb
  constructor: ->
    if !Router.instance
      Router.instance = this
      Backbone.Router.apply Router.instance, arguments
    Router.instance
  
  prev: Backbone.history.fragment

  routes:
    '': 'index'
    'index.html' : 'index'
    'about.html': 'about'
    'projects.html': 'projects'
    'projects/:name': 'project-single'
  
  'index': ->
    content.render '/index.html', ->
      content.show()
      new HomeView().render()

  'about': ->
    content.render '/about.html', ->
      content.show()

  'projects': ->
    content.render '/projects.html', ->
      content.show()
      new ProjectThumbnailView().render()
      new ShowMoreCommitsView()

  'project-single': (name) ->
    content.render "/projects/#{ name }", ->
      new ProjectImageView().render()
