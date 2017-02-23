class Game
  constructor: (data, element) ->
    self = @
    if not GameConfig then throw new Error("GameConfig is not defined!")
    @$el = $(element)
    @data = data
    @slideFormat = _.find(GameConfig.slideFormatList,
                          (aformat) -> aformat.value == data.slide_image_count)
    if not @slideFormat?
      throw new Error("Unknown slide_image_count: " + data.slide_image_count)
    if @data.slide_image_count < 2
      throw new Error("slide_image_count should  be more than one")     
    if @data.slide_image_count > @data.images
      throw new Error("slide_image_count should not be more than images length")
    @bsSlideCol = Math.floor(12 / @slideFormat.columnsLength)
    @gameover = false
    @gamestarted = false

  @writeResult: (data, elem) ->
    if not GameConfig.resultTemplate?
      throw new Error("result template is not loaded")
    # score, wronghits,
    $(elem).append(GameConfig.resultTemplate(data))

  writeResult: (elem) ->
    Game.writeResult(@, elem)
  
  @_loadTemplate: (name) ->
    # load game template
    if not GameConfig["#{name}Template"]
      if GameConfig["_promise_#{name}Template"]?
        return GameConfig["_promise_#{name}Template"]
      return GameConfig["_promise_#{name}Template"] = \
        $.ajax(GameConfig["#{name}TemplateUrl"]).then (tpl) ->
          delete GameConfig["_promise_#{name}Template"]
          if typeof tpl != 'string'
            throw new Error("String response expected got #{typeof tpl}")
          GameConfig["#{name}Template"] = _.template(tpl) # define template
    else if typeof GameConfig["#{name}Template"] == 'string'
      GameConfig["#{name}Template"] = _.template(GameConfig["#{name}Template"])
    deferred = $.Deferred()
    deferred.resolve()
    return deferred.promise()
  # static method prepares required data to initiate the game
  @prepare: ->
    self = @
    promises = []
    _.each(['game','gameSlide','result'], (name) ->
      promises.push self._loadTemplate(name)
    )
    $.when.apply($, promises)

  _loadImage: (url) ->
    deferred = $.Deferred()
    img = new Image()
    img.src = url
    img.onload = ->
      deferred.resolve()
    img.onerror = ->
      deferred.reject("Could not load image: " + url)
    deferred.promise()

  load: ->
    self = @
    promises = [ Game.prepare() ]
    _.each(@data.images, (img) ->
      promises.push self._loadImage(img.image_url)
    )
    $.when.apply($, promises).then ->
      self._initiate()

  _initiate: ->
    if @gameover
      return # destroyed
    self = @
    data = @data
    tdata =
      slideFormat: @slideFormat
    @$el.html(GameConfig.gameTemplate(tdata))
    # draw empty slide
    emptyslide =
      empty: true
      slide: {
        images: _.map(_.range(data.slide_image_count), -> null)
      }
      bscol: @bsSlideCol
      slideFormat: @slideFormat
    @$el.find('.slide').html(GameConfig.gameSlideTemplate(emptyslide))
    # game calcs
    @slidesCount = Math.floor(data.total_time / data.slide_timeout)
    @slides = _.map(_.range(@slidesCount), (index) ->
      match = Math.random() < data.have_match_proportion
      existing_len = if match then 1 else 0
      unique_len = data.slide_image_count - existing_len
      allimages = data.images.concat()
      images = _.map(_.range(unique_len), ->
        if allimages.length == 0
          throw new Error("Fatal error, data changed at init")
        allimages.splice(Math.floor(Math.random() * allimages.length), 1)[0]
      )
      _.each(_.range(existing_len), ->
        images.push images[Math.floor(Math.random() * images.length)]
      )
      { index: index, images: images, match: match }
    )
    @slidesqueue = @slides.concat()
    @score = 0
    @wronghits = 0
    @_bindhitkey = ($evt) ->
      if not self.gameover and self.gamestarted
        if $evt.which == GameConfig.hitKeyCode
          self.hit()
        else if $evt.which == GameConfig.exitKeyCode
          self.exit()
    $(window).bind('keydown', @_bindhitkey)
    @_bindresize = ->
      self._setCanvasSize()
      self._setSlideSize()
    $(window).bind('resize', @_bindresize)
    self._setCanvasSize()
    self._setSlideSize()
  
  destroy: ->
    if @gameover
      return # already destoryed
    @gameover = true
    $(window).unbind('keydown', @_bindhitkey)
    $(window).unbind('resize', @_bindresize)
    if @_nextSlideTO?
      clearTimeout(@_nextSlideTO)
      @_nextSlideTO = null

  _setCanvasSize: ->
    $game = @$el.find('.game')
    offset = $game.offset()
    canvasAllowedHeight = $(window).height() - offset.top
    height = _.max([GameConfig.heightInfo.min,
                   _.min([GameConfig.heightInfo.max,
                          Math.floor(canvasAllowedHeight)])])
    $game.css('height', height+'px')
    @height = height

  _setSlideSize: ->
    if not @height?
      return
    $images = @$el.find('.images')
    images_offset = $images.position()
    images_height = @height - images_offset.top
    row_len = Math.ceil(@data.slide_image_count / @slideFormat.columnsLength)
    image_height = Math.floor(images_height / row_len)
    $images.find('.image-col').css('height', image_height+'px')
  
  _nextSlide: ->
    self = @
    # score calc
    slide = @slidesqueue.shift()
    if not slide?
      # game finished
      @currentslide = null
      @destroy()
      $(@).trigger('gameover')
      return
    slide.starttime = new Date().getTime()
    @currentslide = slide
    tdata =
      empty: false
      slide: slide
      bscol: @bsSlideCol
      slideFormat: @slideFormat
    @$el.find('.slide').html(GameConfig.gameSlideTemplate(tdata))
    @_setSlideSize()
    # timeout for next slide
    @_nextSlideTO = setTimeout(->
      self._nextSlideTO = null
      # first game control flow
      # no hit
      self.score += if self.currentslide.match then 0 else 1
      self.currentslide.correct = not self.currentslide.match
      self._nextSlide()
    , @data.slide_timeout)

  hit: ->
    if not @currentslide?
      throw new Error("hit outside game time")
    if @_nextSlideTO?
      clearTimeout(@_nextSlideTO)
      @_nextSlideTO = null
    # second game control flow
    @currentslide.timeofhit = new Date().getTime() - @currentslide.starttime
    @currentslide.correct = @currentslide.match
    @wronghits += if @currentslide.match then 0 else 1
    @score += if @currentslide.match then 1 else 0
    @_nextSlide()

  exit: ->
    @currentslide = null
    @destroy()
    $(@).trigger('gameover')
  
  _startcountdown: ->
    # show ready, steady, go then start
    deferred = $.Deferred()
    $countdown = @$el.find('.countdown')
    turns = [ 'ready', 'steady', 'go' ]
    prevturn = null
    eachtimeout = GameConfig.countdownTime / turns.length
    start = ->
      if prevturn?
        $countdown.toggleClass('fadeout', false)
        $countdown.toggleClass(prevturn + '-turn', false)
      aturn = turns.shift()
      if not aturn?
        $countdown.hide()
        deferred.resolve()
        return
      $countdown.toggleClass(aturn + '-turn', true)
      if GameConfig.countdownFreezeRatio < 1
        ratio = if GameConfig.countdownFreezeRatio  <= 0 then 0.01 \
                   else GameConfig.countdownFreezeRatio
        setTimeout(->
          $countdown.toggleClass('fadeout', true)
        , ratio * eachtimeout)
      prevturn = aturn
      setTimeout(start, eachtimeout)
    $countdown.show()
    start()
    deferred.promise()

  start: ->
    self = @
    @_setCanvasSize()
    @_setSlideSize()
    @_startcountdown().then ->
      self.gamestarted = true
      self._nextSlide()
    
    
window.Game = Game
