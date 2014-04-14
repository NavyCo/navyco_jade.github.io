'use strict'

if not DEBUG?
  this.DEBUG = true

$w = $ window
$doc = $ document

# 'safeAnimate' method
jQuery.fn.safeAnimate = do ->
  _protoSlice = Array::slice
  
  return ->
    args = _protoSlice.call arguments, 0
    return this.stop().animate args...

if not $.support.transition
  $.fn.transition = $.fn.animate

jQuery.fn.centerHeight = ->
  $this = $ this
  Math.round $this.position().top + $this.height() * 0.5

# WebP support
jQuery.fn._enableWebP = -> this

Modernizr.on 'webp', (result) ->
  if result
    jQuery.fn._enableWebP = ->
      this.each ->
        $this = $ this
        webpPath = $this.attr 'data-original'
          .replace 'img/', 'img/webp/'
          .replace '.jpg', '.webp'
          .replace '.png', '.webp'
        $this.attr 'data-original', webpPath
      this

# Page Visibility API
if typeof document.hidden isnt 'undefined'
  hidden = 'hidden'
  visibilityChange = 'visibilitychange'
else if typeof document.mozHidden isnt 'undefined'
  hidden = 'mozHidden'
  visibilityChange = 'mozvisibilitychange'
else if typeof document.msHidden isnt 'undefined'
  hidden = 'msHidden'
  visibilityChange = 'msvisibilitychange'
else if typeof document.webkitHidden isnt 'undefined'
  hidden = 'webkitHidden'
  visibilityChange = 'webkitvisibilitychange'
