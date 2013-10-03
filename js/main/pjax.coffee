$ ->
  $(document).pjax 'a:not(href*="http")', {
    container: '#content'
    fragment: '#content'
  }
  