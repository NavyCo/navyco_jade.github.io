"use strict"

if not DEBUG?
  this.DEBUG = true

if DEBUG
  console.log '--- DEBUG MODE ---'


ua = navigator.userAgent

isMobile = do ->
  return ua.indexOf('like Mac OS X') isnt -1 or
         ua.indexOf('Android') isnt -1 or
         (ua.indexOf('Mobile') isnt -1 and ua.indexOf('Firefox') isnt -1)

$w = $ window
$doc = $ document

# 'safeAnimate' メソッド - アニメーション開始前に、それまでのアニメーションを中止する
_protoSlice = Array::slice

jQuery.fn.safeAnimate = ->
  args = _protoSlice.call arguments, 0
  return this.stop().animate args...
