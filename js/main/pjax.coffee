$ ->
  # 外部リンクと bxSlider の UI には pjax を適用しない
  if ($.support.pjax)
    $(document).on 'click', 'a:not([href*="//"], .bx-wrapper *)', (e) ->
      $('main').fadeTo 2, 0.01
      
      $.pjax.click e, {
        container: '#content'
        fragment: '#content'
      }
  
  slider = $('.bxslider')

  resetSlider = ->
    # 既存のスライダーを削除
    $('.bx-controls, .bx-clone').remove()
    $(".bx-wrapper #{ slider.selector }").unwrap().unwrap()
    
    # pjax 向けバッドノウハウ
    # TODO: 原因の発見
    _redraw = ->
      setTimeout ->
        slider.redrawSlider()
      , 60

    slider = $(slider.selector).bxSlider({
      onSliderLoad: _redraw
    })
    
    _redraw()
  
  resetContent = (e, xhr) ->
    if xhr?.getResponseHeader 'x-pjax-title'
      document.title = xhr.getResponseHeader 'x-pjax-title'
    
    if location.href.indexOf('projects/') isnt -1
      resetSlider()
    
  resetContent()
  
  $doc.on 'pjax:end', null, resetContent
  $doc.on 'pjax:complete', null, ->
    $('main').fadeTo(150, 1)

    
  

  
