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
      if not self.$form.parsley().isValid()
        return # validation is not ready
      # not defined yet
      self._formData()
      .then (data) ->
        self.$form.find('.error-msg').html("").hide()
        $(self).trigger('submit', data)
      .catch (err) ->
        self.$form.find('.error-msg').html(err).show()
    )
    @$imagesdiv = @$form.find('[data-images-form]')
    if @$imagesdiv.length != 1
      throw new Error("GameSetup form needs one and only one data-images-form")
    @storedimages = []
    imgtypepttrn = /^image\//
    @$form.find('[name=images_select]').bind('change', ->
      $imagesinp = $(@)
      files = _.map(@files, (file) -> file) # to array
      # clear files
      $newinp = $imagesinp.clone()
      $newinp.bind('change', arguments.callee)
      $imagesinp.replaceWith($newinp)
      storeAnImage = ->
        file = files.shift()
        if not file
          # complete
          return
        if imgtypepttrn.test(file.type)
          self.addImage(file).then(->
            storeAnImage()
          ) # never throws to catch
        else
          storeAnImage()
      storeAnImage()
    )
    @$form.find('.clear-images').bind('click', ->
      self.storedimages = []
      self.$imagesdiv.children().remove()
    )
    @$imagesdiv.on('click', '.remove-image', ($evt) ->
      $evt.preventDefault()
      $imagectr = $($evt.target).parents('.game-image-ctr')
      if $imagectr and self.$imagesdiv[0] == $imagectr.parent()[0]
        imagectr = $imagectr[0]
        index = _.find(self.$imagesdiv.children(), (c) -> c == imagectr)
        if `index !== undefined`
          self.storedimages.splice(index, 1)
          $imagectr.remove()
    )
  load: ->
    self = @
    promises = []
    # load image template
    if not GameConfig.imageFormTemplate then \
      promises.push $.ajax(GameConfig.imageFormTemplateUrl).then (tpl) ->
        if typeof tpl != 'string'
          throw new Error("String response expected got #{typeof tpl}")
        GameConfig.imageFormTemplate = tpl # define template
        GameConfig._imageFormTemplate = null
    # promise on ready
    $.when(promises).then ->
      self._initiate()

  _initiate: ->
    @resetSelectOptions()
    @$form.parsley(GameConfig.ParsleyConfig)

  resetSelectOptions: ->
    $selectReset(@$form.find('[name=slide_image_count]').first(),
                 GameConfig.slideFormatList)
    $selectReset(@$form.find('[name=type]').first(), GameConfig.typeList)
    $selectReset(@$form.find('[name=have_match_proportion]').first(),
                 GameConfig.haveMatchProportionList)
    $selectReset(@$form.find('[name=slide_timeout]').first(),
                 GameConfig.slideTimeoutList)
    $selectReset(@$form.find('[name=total_time]').first(),
                 GameConfig.totalTimeList)

  _file2url: (file) ->
    deferred = $.Deferred()
    reader = new FileReader()
    reader.addEventListener('load', ->
      deferred.resolve(reader.result)
    , false)
    reader.readAsDataURL(file)
    deferred.promise()

  addImage: (file) ->
    self = @
    @_file2url(file).then( (imageUrl) ->
      GameConfig._imageFormTemplate ?= _.template(GameConfig.imageFormTemplate)
      imagedata =
        imageUrl: imageUrl
        file: file
      self.storedimages.push(imagedata)
      self.$imagesdiv.append(GameConfig._imageFormTemplate({
        imageUrl: imageUrl
      }))
    )

  _formData: ->
    promises = []
    ret = {}
    self = @
    erridx = _.find([
      {n: 'total_time', c:parseInt}, {n: 'slide_image_count', c:parseInt}
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
      deferred = $.Deferred()
      deferred.reject("Form input is not valid")
      return deferred.promise()
    if @storedimages.length < GameConfig.leastImageLength
      deferred = $.Deferred()
      deferred.reject("Need for at #{GameConfig.leastImageLength} least images to build the game")
      return deferred.promise()
    ret.images = @storedimages 
    # update stored images if needed
    $images_ctr = @$imagesdiv.children()
    _.each(@storedimages, (imagedata, index) ->
      if index < $images_ctr.length
        inp = $($images_ctr[index]).find('input[type=file]')[0]
        if inp and inp.files.length == 1 and inp.files[0] != imagedata.file
          # update image data
          newfile = inp.files[0]
          promises.push(self._file2url(newfile).then( (imageUrl) ->
            imagedata.imageUrl = imageUrl
            imagedata.file = newfile
          ))
      
    )
    $.when(promises).then(-> ret)
    
    
window.GameSetup = GameSetup
