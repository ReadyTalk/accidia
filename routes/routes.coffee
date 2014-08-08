###
File: routes.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: routes for ReadyTalk Chat
###




###
@Function: mustBeSignedIn
@Description: Checks whether user is logged in and redirects non-logged-in users to home page.
@params: None
@return: bool indicating whether or not user is logged in
@pre: None
@post: Non-logged-in users are redirected to the home page.
###
mustBeSignedIn = ->
  if Meteor.userId()
    return true
  else
    Router.go("/")
    return false

# checks that user is logged in on every page except 'home' and 'tests'.
Router.onBeforeAction(mustBeSignedIn, {except: ['home', 'tests']})
Router.onBeforeAction('dataNotFound')
Router.onBeforeAction('loading')

Router.configure ->
  loadingTemplate: 'loading'
  notFoundTemplate: '404'


#define routes
Router.map ->

  @route 'chat',
    path: '/chat/:room_name'
    notFoundTemplate: 'home'
    loadingTemplate: 'Loading'
    onBeforeAction: ->
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('rooms'),
      Meteor.subscribe('users'),
      Meteor.subscribe('bookmarks', @params.room_name),
      Meteor.subscribe('notifications'),
      Meteor.subscribe('usersNoteCount'),
      Meteor.subscribe('system_messages', @params.room_name)]
    data: ->
      if Meteor.user()
        Rooms.findOne({room_name: @params.room_name})

  @route 'home',
    path: '/'
    notFoundTemplate: 'home'
    loadingTemplate: 'Loading'
    onBeforeAction: ->
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('rooms'), Meteor.subscribe('users'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount')]
    data: ->
      Meteor.user()

  if Meteor.settings.public.mode != "production"
    @route 'tests',
      path: '/tests'
      onBeforeAction: ->
        $('body').addClass('skin-black fixed')
      onStop: ->
        $('body').removeClass('skin-black fixed')
      waitOn: ->
        [Meteor.subscribe('rooms'), Meteor.subscribe('users'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount')]

  @route 'create_room',
    path: '/create_room'
    onBeforeAction: ->
      FlashMessages.clear()
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('rooms'), Meteor.subscribe('users'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount')]


  @route 'bookmarks',
    path: '/bookmarks'
    notFoundTemplate: 'home'
    loadingTemplate: 'Loading'
    onBeforeAction: ->
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('bookmarks'), Meteor.subscribe('rooms'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount'), Meteor.subscribe('users')]
    data: ->
      if Meteor.user()
        Bookmarks.find({})

  @route 'notifications',
    path: '/notifications'
    notFoundTemplate: 'home'
    loadingTemplate: 'Loading'
    onBeforeAction: ->
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('bookmarks'), Meteor.subscribe('rooms'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount'), Meteor.subscribe('users')]
    data: ->
      if Meteor.user()
        Notifications.find({})

  @route '404',
    path: '*'
    loadingTemplate: 'Loading'
    onBeforeAction: ->
      $('body').addClass('skin-black fixed')
    onStop: ->
      $('body').removeClass('skin-black fixed')
    waitOn: ->
      [Meteor.subscribe('rooms'), Meteor.subscribe('users'), Meteor.subscribe('notifications'), Meteor.subscribe('usersNoteCount')]
