$('.two-column').wookmark
  align: 'left'
  autoResize: true
  container: $('.columns')
  direction: 'left'
  itemWidth:360
  flexibleWidth: '50%'
  offset: 36
  resizeDelay: 0
  onLayoutChanged: ->
    if parseInt(this.handler[0].style.width, 10) is this.itemWidth
      this.handler.css('width', '')
      this.handler.css('position', '')
      this.container.css('height', '')

# 右上に表示する要素
go = $ '<div id="go"></div>'

$('.wzide-image')
.on 'mouseover', ->
  $(this).children('img').animate {
    'border-width': '24px'
    'top': '-12px'
    'left': '-12px'
  }, 100
  
  go.css 'top', - $(this).children('img').height() + 'px'
  $(this).append go

.on 'mouseout', ->
  $(this).children('img').animate {
    'opacity': '1'
  }, 100
  
  go.remove()