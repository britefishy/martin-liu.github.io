'use strict'
angular.module('m-util',[]).factory 'Util', ($modal, $timeout, $location
, $anchorScroll, $window, $http, $templateCache
, $compile, $q, $route, Cache) ->
  class Util
    alertTpl = 'partials/modal/alert.html'
    # Create a dialog in specific template
    createDialog: (template, scope, thenFunc, options) ->
      options ?= {}
      options = angular.extend {
        backdropFade: true
        templateUrl: template
        controller: ["$scope", "$modalInstance", "scope",
        ($scope, $modalInstance, scope)->
          $scope = angular.extend($scope, scope)
          $scope.animate = Config.default.modalAnimateIn
          $scope.close = (data) ->
            $scope.animate = Config.default.modalAnimateOut
            $timeout (-> $modalInstance.close(data)),500
        ]
        resolve: {
          scope : ->
            scope
        }
      }, options
      dialog = $modal.open options
      dialog.result.then thenFunc
      dialog

    alert: (message, type, thenFunc)->
      mclass = switch type
        when 'success' then 'alert-success'
        when 'fail' then 'alert-danger'
        when 'confirm' then 'alert-warning'
      scope =
        message : message
        type : type
        class: mclass
      @createDialog alertTpl, scope, thenFunc

    success: (message, thenFunc)->
      @alert message, 'success', thenFunc

    fail: (message, thenFunc)->
      @alert message, 'fail', thenFunc

    confirm: (message, thenFunc)->
      @alert message, 'confirm', thenFunc

    # Compile a template then resolve the html
    compileTemplate: (templateUrl, scope) ->
      defer = $q.defer()
      loader = $http.get templateUrl, {cache: $templateCache}
      loader.success((html)->
        defer.resolve $compile(html)(scope)
      )
      return defer.promise

    toggleFullscreen: (e)->
      angular.element(document.body).toggleClass 'fullscreenStatic'
      angular.element(e).toggleClass 'fullscreen'

    daysBetween: (date1, date2) ->
      # Get 1 day in milliseconds
      one_day = 1000 * 60 * 60 * 24

      # Convert both dates to milliseconds
      date1_ms = date1.getTime()
      date2_ms = date2.getTime()

      # Calculate the difference in milliseconds
      difference_ms = Math.abs date2_ms - date1_ms

      # Convert back to days and return
      Math.round difference_ms / one_day

    formatDate: (date) ->
      if date == '0000-00-00 00:00:00'
        ''
      else
        date

    truncDate: (date) ->
      if !date || date == '0000-00-00'
        ''
      else
        date.match(/\S+/g)[0]

    truncateCharacter: (input, chars, breakOnWord) ->
      if isNaN chars
        return input
      if chars <= 0
        return ''
      if input && input.length >= chars
        input = input.substring 0, chars

        if !breakOnWord
          lastspace = input.lastIndexOf ' '
          # Get last space
          if lastspace != -1
            input = input.substr 0, lastspace
        else
          while input.charAt(input.length - 1) == ' '
            input = input.substr 0, input.length -1
        return input + '...'
      return input

    redirect: (path, force) ->
      path = path.replace '%', ''
      if $location.url() != path
        $location.url path
      else
        if force
          $route.reload()

    reload: ->
      $route.reload()

    scrollTo: (height) ->
      $window.scrollTo 0, height

    setUpScrollHandler: (elId, event) ->
      $timeout ->
        el = document.getElementById elId
        if el
          $anchorScroll()
          angular.element(el).triggerHandler event
      , 0

    getParams: ->
      $location.search()

    getUserParam: (user)->
      nt : user.nt
      fullname : user.displayName
      label : user.label

    getWithCache: (key, isSession, getFunc, timeout)->
      cache = Cache
      if isSession
        cache = Cache.session
      defer = $q.defer()
      data = cache.get key
      if data
        defer.resolve data
        return defer.promise
      else
        promise = getFunc()
        promise.then (data)->
          cache.set key, data, timeout
        return promise

    capitalize: (str) ->
      str.charAt(0).toUpperCase() + str.slice(1)

    solrEscape: (q)->
      q.replace /[+\-\!\(\)\{\}\[\]\^"~\*\?:\\]+/g, ' '

    removeHtmlTags: (str)->
      str.replace /<[^>]*>?/g, ''

    waitUntil: (func, check, interval = 300, maxTime = 100)->
      doWait = (time)->
        defer = $q.defer()
        if time == 0
          defer.reject('exceed 100 times check')
        ret = func()
        if check ret
          defer.resolve ret
        else
          $timeout =>
            doWait(time - 1).then (ret)->
              defer.resolve ret
            , (err)->
              defer.reject err
          , interval
        defer.promise
      doWait(maxTime)

  new Util()
