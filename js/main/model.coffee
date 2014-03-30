Page = Backbone.Model.extend
  categorize: ->
    _frag = Backbone.history.fragment
    _category = 'index'
    _basename = 'index'

    if _frag.contains 'projects'
      _category = 'projects'
      for _name of routerData
        if location.href.contains "#{ _name }."
          _basename = _name
    else if _frag.contains 'about'
      _category = 'about'
      _basename = 'about'
    
    @set
      category: _category
      basename: _basename
