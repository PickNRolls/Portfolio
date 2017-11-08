class ElementCoordinate
  constructor: (@_elem) ->
    @top = @_elem.getBoundingClientRect().top + pageYOffset
    @left = @_elem.getBoundingClientRect().left + pageXOffset

  refresh: ->
    @top = @_elem.getBoundingClientRect().top + pageYOffset
    @left = @_elem.getBoundingClientRect().left + pageXOffset

class Widget
  constructor: (config) ->
    @_elem = config.element ? throw new Error 'No element for widget!'
    if typeof config.classes is 'string'
      arr = []
      arr.push config.classes
      @_classes = arr
    else
      @_classes = config.classes ? []

  start: ->
    return new Throw 'Method start must be overriden!'

  getElement: ->
    return @_elem

  getClassList: (likeString) ->
    if likeString then return @_classes.join ' '
    return @_classes

  #################
  # Private methods
  #################

  _init: ->
    @_elem.classList.add className for className in @_classes





class Clock extends Widget
  constructor: (config) ->
    super config
    @clickable = config.clickable ? false
    @_classes.push 'clock-widget'
    @_clockId = null
    @_timeNow = null
    @_hour = null
    @_minute = null
    @_second = null

    @_ghost =
      elem: null
      i: 1
      reverse: no
      id: null

    do @_init

  start: ->
    @_elem.classList.remove 'clock-widget-stopped'
    do @_tick

  stop: =>
    clearInterval @_clockId
    @_elem.classList.add 'clock-widget-stopped'
    do @_startGhost

  toggle: ->
    if @_elem.classList.contains 'clock-widget-stopped' then do @start else do @stop


  #################
  # Private methods
  #################

  _init: ->
    do super
    if @clickable
      @_elem.addEventListener 'click', @toggle.bind @
      @_elem.style.cursor = 'pointer'


  _tick: ->
    do func = =>
      @_timeNow = new Date
      @_hour = '' + do @_timeNow.getHours
      @_minute = '' + do @_timeNow.getMinutes
      @_second = '' + do @_timeNow.getSeconds

      do @_check
      do @_render
    @_clockId = setInterval func, 1000

  _check: ->
    if @_hour.length is 1 then @_hour = 0 + @_hour
    if @_minute.length is 1 then @_minute = 0 + @_minute
    if @_second.length is 1 then @_second = 0 + @_second

  _render: ->
    @_elem.textContent = "#{@_hour}:#{@_minute}:#{@_second}"

  _startGhost: ->
    elemCoord = new ElementCoordinate @_elem
    @_ghost.elem = @_elem.cloneNode on
    style = @_ghost.elem.style

    style.cursor = 'default'
    style.top = elemCoord.top + 'px'
    style.left = elemCoord.left + 'px'
    @_ghost.elem.classList.add 'clock-widget-ghost'
    document.body.append @_ghost.elem


    @_ghost.i = 1
    @_ghost.reverse = no
    @_ghost.id = null
    do @_animateGhost

  _animateGhost: ->
    @_ghost.elem.style.transform = "scale(#{@_ghost.i})"
    @_ghost.id = requestAnimationFrame @_animateGhost.bind @

    if @_ghost.i > 1.5
      @_ghost.reverse = on

    if @_ghost.reverse
      @_ghost.i -= .1
      if @_ghost.i is .9 then do @_stopAnimateGhost
      return

    @_ghost.i += .1

  _stopAnimateGhost: =>
    cancelAnimationFrame @_ghost.id
    do @_ghost.elem.remove





class ScrollSlider extends Widget
  constructor: (config) ->
    super config
    @_classes.push 'scroll-slider'

    @_scroll = null
    @_sliderWidth = null
    @_sliderCoord = null
    @_scrollWidth = null
    @_scrollCoord = null
    @_scrollWidth = null
    @_dragged = no

  start: ->
    do @_init
    do @_handleListeners

  #################
  # Private methods
  #################

  _init: ->
    do super
    if not @_elem.querySelector '[data-scroll-slider]'
      @_scroll = document.createElement 'div'
      @_scroll.setAttribute 'data-scroll-slider', 'on'
      @_scroll.classList.add 'scroll'
      @_elem.insertBefore @_scroll, @_elem.firstChild
    @_sliderWidth = @_elem.offsetWidth
    @_sliderCoord = new ElementCoordinate @_elem
    @_scrollWidth = @_scroll.offsetWidth

  _handleListeners: ->
    @_elem.addEventListener 'mousedown', (e) =>
      @_mousedown e
      document.addEventListener 'mousemove', @_mousemove
      @_elem.ondrag = -> return no
      document.addEventListener 'mouseup', @_mouseup

    @_elem.addEventListener 'click', (e) =>
      target = e.target
      if not target.classList.contains('scroll-slider') ||
      target.getAttribute 'data-scroll-slider' then return

      @_scroll.style.left = e.pageX - @_sliderCoord.left - @_scrollWidth / 2 + 'px'
  _mousedown: (e) ->
    target = e.target
    if not target.classList.contains 'scroll' then return
    @_scrollCoord = new ElementCoordinate target
    document.body.style.cursor = 'pointer'
    @_dragged = on

  _mousemove: (e) =>
    if not @_dragged then return
    @_scroll.style.left = e.pageX - @_sliderCoord.left + 'px'
    do @_scrollCoord.refresh
    do @_checkEdges

  _mouseup: =>
    document.removeEventListener 'mousemove', @_mousemove
    document.removeEventListener 'mouseup', @_mouseup
    @_dragged = no
    document.body.style.cursor = ''

  _checkEdges: ->
    rightEdge = @_sliderWidth - @_scrollWidth
    leftEdge = @_scrollCoord.left - @_sliderCoord.left
    if leftEdge < 0 then @_scroll.style.left = 0
    if leftEdge > rightEdge then @_scroll.style.left = rightEdge + 'px'





class SelectList extends Widget
  constructor: (config) ->
    super config
    @_classes.push 'select-list'

    @_items = []
    @_selected = []
    @_lastClicked = null

  getSelected: ->
    return @_selected

  getItems: ->
    return @_items

  start: ->
    do @_init
    do @_handleListeners

  #################
  # Private methods
  #################

  _init: ->
    do super
    for element in @_elem.children
      if element.tagName isnt 'LI' then continue
      element.classList.add 'select-list__item'
      @_items.push element

  _handleListeners: ->
    @_elem.addEventListener 'click', (e) =>
      target = @_checkClick e
      if target is no then return

      if e.ctrlKey
        @_selectWithCtrl target
        return

      if e.shiftKey
        @_selectWithShift target
        return

      @_select target

    @_elem.onselectstart = -> return no

  _checkClick: (e) ->
    target = e.target
    if target.classList.contains 'select-list' then return no
    while not target.classList.contains 'select-list__item'
      target = target.parentElement

    if target.classList.contains 'select-list__item'
      return target
    else
      return no

  _selectWithCtrl: (target) ->
    target.classList.toggle 'selected'
    @_lastClicked = target
    do @_pushSelected

  _select: (target) ->
    item.classList.remove 'selected' for item in @_items
    target.classList.add 'selected'
    @_lastClicked = target
    do @_pushSelected

  _selectWithShift: (target) ->
    position = @_lastClicked.compareDocumentPosition target

    if position is 2
      while previous isnt target
        previous = @_lastClicked.previousElementSibling
        previous.classList.add 'selected'
        @_lastClicked = previous
    else if position is 4
      while next isnt target
        next = @_lastClicked.nextElementSibling
        next.classList.add 'selected'
        @_lastClicked = next

    do @_pushSelected

  _pushSelected: ->
    @_selected = []
    for item in @_items
      if item.classList.contains 'selected' then @_selected.push item





class Counter extends Widget
  constructor: (config) ->
    super config
    @_classes.push 'counter-widget'

    @_panel = null
    @_step = config.step ? 1
    @_num = 0

  start: ->
    do @_init

  getValue: ->
    return @_num

  #################
  # Private methods
  #################

  _init: ->
    do super
    do @_createButtons
    do @_handleListeners
    do @_append

  _createButtons: ->
    @_minus = document.createElement 'div'
    @_minus.classList.add 'counter-widget__minus'
    @_minus.textContent = '-'

    @_plus = document.createElement 'div'
    @_plus.classList.add 'counter-widget__plus'
    @_plus.textContent = '+'

    @_panel = document.createElement 'div'
    @_panel.classList.add 'counter-widget__panel'
    @_panel.textContent = 0

  _handleListeners: ->
    @_minus.addEventListener 'click', =>
      @_changeCurrentNum on
      do @_renderNum
    @_plus.addEventListener 'click', =>
      @_changeCurrentNum no
      do @_renderNum

    @_minus.onselectstart = -> return no
    @_plus.onselectstart = -> return no

  _renderNum: ->
    @_panel.textContent = @_num

  _changeCurrentNum: (minus) ->
    if minus
      @_num -= @_step
      if @_num < 0 then @_num = 0
      return

    @_num += @_step

  _append: ->
    @_elem.append @_minus, @_panel, @_plus





clock = new Clock
  element: document.getElementById 'clock'
  classes: 'my-clock'
  clickable: on
window.clock = clock
do clock.start


scrollSlider = new ScrollSlider
  element: document.getElementById 'scroll-slider'
  classes: 'my-slider'
window.scrollSlider = scrollSlider
do scrollSlider.start


selectList = new SelectList
  element: document.getElementById 'select-list'
  classes: 'my-list'
window.selectList = selectList
do selectList.start


counter = new Counter
  element: document.getElementById 'counter'
  classes: 'my-counter'
  step: 2
window.counter = counter
do counter.start

document.addEventListener 'selectstart', (e) -> do e.preventDefault