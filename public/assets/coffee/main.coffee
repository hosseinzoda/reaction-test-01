currentpage = 'setup'
showpage = (page) ->
  currentpage = page if page
  $('#navbar li').each(->
    $el = $(@)
    $el.toggleClass('active',
                    $el.find('a[data-name]').data('name') == currentpage)
  )
  $('.pages-container > div').hide()
  $("##{currentpage}-page").show()
cleargame = ->
  $game = $('#game')
  if $game.length > 0
    agame = $game.data('game')
    if agame then agame.destroy()
    $game.remove()
$(-> # on DOMContentLoaded
  # click hooks
  initialized = false
  $('#navbar').on('click', 'a[data-name]', ($evt) ->
    $evt.preventDefault()
    if not initialized
      return
    $el = $(@)
    showpage($el.data('name'))
    $('#navbar li.active').toggleClass('active', false)
    $el.parent().toggleClass('active', true)
    $(window).trigger("x-change-page")
    $(window).trigger("x-change-page-#{currentpage}")
  )
  promises = []
  # start loading
  gamesetup = new GameSetup($('#setup-form'))
  $(gamesetup).bind('submit', ($evt, data) ->
    # initiate a game
    # extra field addon
    $('body').toggleClass('fullscreen', $('[name=fullscreen]').first().prop('checked'))
    initGame(data).then ->
      $('body').toggleClass('fullscreen', false)
  )
  promises.push gamesetup.load()

  # prepare game for future instantiation 
  promises.push Game.prepare()
  
  $.when.apply($, promises)
    .then ->
      # ready
      initialized = true
      $('#loading-page').hide()
      showpage()
      $(window).trigger('x-change-page-' + currentpage)
    .catch (err) ->
      console.error(err)
      alert(err)
)

$(window).bind('x-change-page', ($evt) ->
  cleargame()
)
# initiate test game on page changed to game
$(window).bind('x-change-page-game', ($evt) ->
  data =
    type: "animals"
    label: "Animals"
    total_time: 0.5 * 60 * 1000
    slide_timeout: 3 * 1000
    have_match_proportion: 0.3
    slide_image_count: 4
    images: _.map([
      "assets/img/arasaac-animals/dog.png"
      "assets/img/arasaac-animals/cat.png"
      "assets/img/arasaac-animals/goat.png"
      "assets/img/arasaac-animals/pig.png"
      "assets/img/arasaac-animals/fish.png"
      "assets/img/arasaac-animals/horse.png"
      "assets/img/arasaac-animals/dolphin.png"
      "assets/img/arasaac-animals/tortoise.png"
      "assets/img/arasaac-animals/lion.png"
      "assets/img/arasaac-animals/giraffe.png"
      "assets/img/arasaac-animals/sheep.png"
      "assets/img/arasaac-animals/donkey.png"
      "assets/img/arasaac-animals/monkey.png"
      "assets/img/arasaac-animals/zebra.png"
      "assets/img/arasaac-animals/tiger.png"
    ], (url) -> { image_url: url })
  initGame(data)
)

window.initGame = (data) ->
  deferred = $.Deferred()
  cleargame()
  playAgain = ->
    $('#play-again-btn').off('click', playAgain)
    window.initGame(data)
  $game = $('<div id="game"></div>').appendTo($('#game-page'))
  game = new Game(data, $('#game'))
  $game.data('game', game)
  showpage('loading')
  game.load()
    .then ->
      showpage('game')
      game.start()
      $(game).bind('gameover', ->
        $('#result-page').html('')
        game.writeResult('#result-page')
        showpage('result')
        $('#play-again-btn').on('click', playAgain)
        deferred.resolve()
      )
    .catch (err) ->
      console.error(err)
      errmsg = if err.message then err.message else err+''
      if err.constructor == window.MediaError
        errmsg = "Could not load media \"#{err.path}\""
      alert(errmsg)
      deferred.reject(err)
  deferred.promise()

$(window).bind('x-change-page-result', ($evt) ->
  data =
    score: 5
    wronghits: 2
    slides: [
      {
        timeofhit: 1503
        correct: true
      }
      {
        timeofhit: 1026
        correct: true
      }
      {
        timeofhit: 2430
        correct: true
      }
      {
        timeofhit: 420
        correct: false
      }
      {
        timeofhit: 702
        correct: true
      }
      {
        timeofhit: 303
        correct: false
      }
    ]
  $('#result-page').html('')
  Game.writeResult(data, '#result-page')
)
