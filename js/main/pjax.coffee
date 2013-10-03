$ ->
  $(document).pjax 'a:not([href*="//"])', {
    container: '#content'
    fragment: '#content'
  }
  
  $(document).on 'ajaxComplete', null, (e, xhr) ->
    if xhr.getResponseHeader 'x-pjax-title'
      document.title = xhr.getResponseHeader 'x-pjax-title'