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
