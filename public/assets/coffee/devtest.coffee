currentpage = 'setup'
showpage = (page) ->
  currentpage = page if page
  $('.pages-container > div').hide()
  $("##{currentpage}-page").show()
$(-> # on DOMContentLoaded
  # click hooks 
  $('#navbar').on('click', 'a[data-name]', ->
    $el = $(@)
    showpage($el.data('name'))
    $('#navbar li.active').toggleClass('active', false)
    $el.parent().toggleClass('active', true)
  )
  # start loading
  gamesetup = new GameSetup($('#setup-form'))
  $(gamesetup).bind('submit', ($evt, data) ->
    console.log(data)
  )
  promises = [ gamesetup.load() ]
  $.when(promises)
    .then ->
      # ready
      $('#loading-page').hide()
      showpage()
    .catch (err) ->
      console.error(err)
  
)
