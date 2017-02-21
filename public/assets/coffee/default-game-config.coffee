window.GameConfig =
  leastImageLength: 4
  imageFormTemplateUrl: 'assets/template/game-image-form.html'
  slideTimeoutList: [
    {
      value: 500
      label: "0.5s"
    }
    {
      value: 1000
      label: "1.0s"
    }
    {
      value: 1500
      label: "1.5s"
    }
    {
      value: 2000
      label: "2s"
    }
    {
      value: 2500
      label: "2.5s"
    }
    {
      value: 3000
      label: "3.0s"
    }
    {
      value: 3500
      label: "3.5s"
    }
  ]
  slideFormatList: [
    {
      value: 4
      label: "Four"
      columnsLength: 2
    }
    {
      value: 6
      label: "Six"
      columnsLength: 3
    }
    {
      value: 8
      label: "Eight"
      columnsLength: 2
    }
    {
      value: 12
      label: "Twelve"
      columnsLength: 3
    }
  ]
  typeList: [
    {
      value: "animals"
      label: "Animals"
    }
    {
      value: "numbers"
      label: "Numbers"
    }
    {
      value: "letters"
      label: "Letters"
    }
    {
      value: "cartoons"
      label: "Cartoons"
    }
  ]
  totalTimeList: [
    {
      value: 2000
      label: "Two minutes"
    }
    {
      value: 3000
      label: "Three minutes"
    }
    {
      value: 5000
      label: "Five minutes"
    }
    {
      value: 6000
      label: "Six minutes"
    }
    {
      value: 8000
      label: "Eight minutes"
    }
  ]
  haveMatchProportionList: ({value: v/100.0,label: v+'%'} \
                            for v in [10..70] by 10)
  # parsley config bootstrap
  ParsleyConfig:
    errorClass: 'has-error'
    successClass: ''
    classHandler: (field) -> field.$element.parents('.form-group')
    errorsContainer: (field) -> field.$element.parents('.form-group')
    errorsWrapper: '<span class="help-block">'
    errorTemplate: '<div></div>'
