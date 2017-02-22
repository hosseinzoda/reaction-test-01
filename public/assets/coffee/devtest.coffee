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
    initGame(data)
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
    total_time: 0.5 * 60 * 1000
    slide_image_count: 4
    slide_timeout: 3 * 1000
    type: 'cartoons'
    have_match_proportion: 0.3
    images: _.map([
      "assets/img/testimgs/Game-Center-icon.png"
      "assets/img/testimgs/1484654403_06-facebook.svg"
      "assets/img/testimgs/angular.svg"
      "assets/img/testimgs/iOS-9-icon-medium.png"
      "assets/img/testimgs/os_macosx_64.png"
      "assets/img/testimgs/1484654395_40-google-plus.svg"
      "assets/img/testimgs/django-logo-negative.png"
      "assets/img/testimgs/1484809285_avatar.svg"
      "assets/img/testimgs/box2d.gif"
      "assets/img/testimgs/ab.png"
      "assets/img/testimgs/cookie.svg"
      "assets/img/testimgs/iphone6.png"
    ], (url) -> { image_url: url })
  initGame(data)
)

window.initGame = (data) ->
  cleargame()
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
      )
    .catch (err) ->
      console.error(err)
      alert(err)

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
