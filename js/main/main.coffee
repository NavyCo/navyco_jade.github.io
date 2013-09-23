$('.two-column').wookmark
  align: 'left'
  autoResize: true
  container: $('.columns')
  direction: 'left'
  itemWidth: 350
  flexibleWidth: '50%'
  offset: 48
  resizeDelay: 0
  onLayoutChanged: ->
    if parseInt(this.handler[0].style.width, 10) is this.itemWidth
      this.handler.css('width', '')
      this.handler.css('position', '')
      this.container.css('height', '')
