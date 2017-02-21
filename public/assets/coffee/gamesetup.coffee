$mkOption = (value, html) -> $('<option>').attr('value', value).html(html)
$selectReset = ($sel, list) ->
  $sel.children().remove()
  _.each(list, (item) ->
    $sel.append($mkOption(item.value, item.label))
  )

window.Parsley
  .addValidator('fileType', {
    requirementType: 'string'
    validateString: (_value, typePttrn, parsleyInstance) ->
      files = parsleyInstance.$element[0].files;
      typeRegex = new RegExp(typePttrn)
      files.length != 1  or typeRegex.test(files[0].type);
    messages: {
      en: 'Selected file is not image',
    }
  });
  
class GameSetup
  constructor: (formel) ->
    self = @
    if not GameConfig then throw new Error("GameConfig is not defined!")
    @$form = $(formel)
    @$form.submit(($evt)->
      $evt.preventDefault()
      if not self.$form.parsley().isValid() or \
         not self._slideFormNeedsUpdateTO?
        return # validation is not ready
      # not defined yet
      data = self._formData()
      if not data?
        console.log("data validation error")
        return # validation fail
      slides = self._slidesFormData(data)
      if not slides?
        console.log("slides validation error")
        return # validation fail
      data.slides = slides
      $(self).trigger('submit', data)
    )
    @$slidesdiv = @$form.find('[data-slides-form]')
    if @$slidesdiv.length != 1
      throw new Error("GameSetup form needs one and only one data-slides-form")
    # input hooks
    @$form.find('[name=slide_count]').bind('input', ->
      self.updateTotalTimeHelper()
      self.setSlidesFormNeedsUpdate()
    )
    @$form.find('[name=slide_timeout]').bind('change', ->
      self.updateTotalTimeHelper()
    )
    @$form.find('[name=slide_image_count]').bind('change', ->
      self.setSlidesFormNeedsUpdate()
    )
  
  load: ->
    self = @
    promises = []
    # load slide template
    if not GameConfig.slideFormTemplate then \
      promises.push $.ajax(GameConfig.slideFormTemplateUrl).then (tpl) ->
        if typeof tpl != 'string'
          throw new Error("String response expected got #{typeof tpl}")
        GameConfig.slideFormTemplate = tpl # define template
        GameConfig._slideFormTemplate = null
    # promise on ready
    $.when(promises).then ->
      self._initiate()

  _initiate: ->
    @resetSelectOptions()
    @$form.parsley(GameConfig.ParsleyConfig)

  updateTotalTimeHelper: ->
    {notvalid,slide_count,slide_timeout} = @_formData() or {notvalid:true}
    @$form.find('[name="slide_count"]').parent().find('.total-time-help')
      .html(if notvalid then "" else \
            "Total time: #{(slide_count * slide_timeout / 1000)\
                            .toFixed(1)} seconds")

  resetSelectOptions: ->
    $selectReset(@$form.find('[name=slide_image_count]').first(),
                 GameConfig.slideFormatList)
    $selectReset(@$form.find('[name=type]').first(), GameConfig.typeList)
    $selectReset(@$form.find('[name=have_match_proportion]').first(),
                 GameConfig.haveMatchProportionList)
    $selectReset(@$form.find('[name=slide_timeout]').first(),
                 GameConfig.slideTimeoutList)

  setSlidesFormNeedsUpdate: ->
    self = @
    if @_slideFormNeedsUpdateTO then clearTimeout(@_slideFormNeedsUpdateTO)
    @_slideFormNeedsUpdateTO = setTimeout(->
      @_slideFormNeedsUpdateTO = undefined
      self.resetSlidesForm()
    , 200)

  resetSlidesForm: ->
    {notvalid,slide_count,slide_image_count} = @_formData() or {notvalid:true}
    if notvalid
      return
    @$slidesdiv.children().remove()
    GameConfig._slideFormTemplate ?= _.template(GameConfig.slideFormTemplate)
    @$slidesdiv.append(GameConfig._slideFormTemplate({ \
      slideIndex: index, \
      slideImageLength: slide_image_count \
     })) for index in [0..slide_count-1]

  _slidesFormData: (formdata) ->
    {notvalid,slide_count,slide_image_count} = formdata
    if notvalid
      return
    self = @
    ret = []
    erridx = _.find(_.range(slide_count), (index) ->
      images = []
      slide = { images: images }
      serridx = _.find(_.range(slide_image_count), (image_index) ->
        $inp = self.$form.find("[name=slide_image_#{index}_#{image_index}]")
        if $inp.length == 0 or not $inp.parsley().isValid()
          return true
        if $inp[0].files.length == 0
          throw Error("Fatal error image validate is not working correctly")
        images.push({
          file: $inp[0].files[0]
        })
        return false
      )
      if `serridx !== undefined`
        return true
      ret.push(slide)
      return false
    )
    if `erridx !== undefined`
      return null
    return ret
  _formData: ->
    ret = {}
    self = @
    erridx = _.find([
      {n: 'slide_count', c:parseInt}, {n: 'slide_image_count', c:parseInt}
      {n: 'slide_timeout', c:parseInt}, {n: 'type'}
      {n:'have_match_proportion', c:parseFloat}
    ], (item) ->
      $inp = self.$form.find("[name=#{item.n}]").first()
      val = $inp.val()
      if $inp.length == 0 or not $inp.parsley().isValid()
        return true
      if typeof item.c == 'function'
        val = item.c(val)
      ret[item.n] = val
      return false
    )
    if `erridx !== undefined`
      return null
    ret
    
window.GameSetup = GameSetup
