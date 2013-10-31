$ ->
  $main = $ 'main'

  # 外部リンクと bxSlider の UI には pjax を適用しない
  if $.support.pjax
    $('#container').on 'click', 'a:not([target], .bx-wrapper *)', (e) ->
      e.preventDefault()

      $('main').fadeTo 4, 0.010, ->
        $.pjax.click e, {
          container: '#content'
          fragment: '#content'
        }
  
  sliderSelector = '.slider'
  # .selector is deprecated
  # http://api.jquery.com/selector/
  slider = $(sliderSelector)

  resetSlider = ->
    # 既存の bxSlider 製のスライダーを削除
    $('.bx-controls, .bx-clone').remove()
    $(".bx-wrapper #{ sliderSelector }").unwrap().unwrap()
    
    # pjax 向けバッドノウハウ
    # TODO: 原因の発見
    _redraw = ->
      setTimeout ->
        $('.bx-wrapper').css 'visibility', 'visible'
        slider.redrawSlider()
      , 60

    slider = $(slider.selector).bxSlider({
      onSliderLoad: _redraw
    })
    
    _redraw()
  
  resetContent = (e, xhr) ->

    if xhr?.getResponseHeader 'X-PJAX-Title'
      document.title = xhr.getResponseHeader 'X-PJAX-Title'
    
    # top page
    if location.href.indexOf('projects') is -1 and
    location.href.indexOf('about') is -1
      $main.addClass 'top'
    else
      $main.removeClass 'top'      
      
    if location.href.indexOf('projects/') isnt -1
      resetSlider()
    
  resetContent()

  _activateTab = ->
    $("#home.active, .tab.active").removeClass('active')

    for page, i in ['about', 'project']
      if location.href.indexOf(page) isnt -1
        $(".tab[href*='#{ page }']").addClass('active')
        break

      if i is 1
        $('#home')
        .addClass('active')


  
  $doc.on 'pjax:start ready', null, (e) ->
    _activateTab()
  
  $doc.on 'pjax:end', null, resetContent
  
  $doc.on 'pjax:complete', null, ->
    $('main').stop().fadeTo(150, 1)
