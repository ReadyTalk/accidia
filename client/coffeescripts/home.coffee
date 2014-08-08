###
File: home.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic for the templates exclusively used in the home page as well as functions and UI (formerly Handlebar) helpers.
###



### @Global_Variables ###

#sets the window name

#reset any flashing title bools so the home page doesn't flash on home
isOnPage = null

#paths for online and offline images
userOnline = "/user-online.png"
userOffline = "/user-offline.png"



### @Template_Functions ###

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables to be ran/assigned when the document is requested.
###
Template.home.created = ->
	window.name = 'Home'
	document.title = "Home | Accidia"

###
@Function: getAvailableRooms
@Description: Returns an array of all rooms sorted in lexicographical order of room name.
@params: None
@return: Room cursor that will return in lexicographically sorted order
@pre: Called within the template named home_logged_in
@post: None
###
Template.home_logged_in.getAvailableRooms = ->
	Rooms.find({}, {sort: {room_name: 1}})



### @Event_Handlers ###

###
@Function: hash of functions for the event handling in the home template
@Description: Defines the click event of the login button
@pre: User must be logged out
@post: Event handlers exist on the home template
###
Template.home.events
	#On button click, window is brought up to continue the authentication process.
	"click #home-content-github-login-button": (e, tmpl) ->
		Meteor.loginWithGithub
			requestPermissions: [
			]

		, (err) ->
			if err
				Session.set "errorMessage", err.reason or "Unknown error"
			else
			return



### @Miscellaneous_Functions ###

###
@Function: getName
@Description: A replication of the server side getName to parse between username and real name
@params: user object
@return: string representing the user's display name
@pre: None
@post: message from input box is inserted into the database
###
getName = (user) ->
	if user.profile.name != "" and user.profile.name != null and user.profile.name != undefined
		user.profile.name
	else
		user.profile.login



### @UI_Helpers ###

###
@Function: setStatusIcon
@Description: Gets and returns the url for a user's online status icon
@params: isOnline attribute of user object
@return: string representing the url of the user's online status image
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper "setStatusIcon", (status)->
	if status == true
		return userOnline
	else
		return userOffline

###
@Function: setStatusIconTitle
@Description: Returns a string representing the online status of a user to be used to set the status icon image title.
@params: isOnline attribute of user object
@return: string representing the user's online status
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper "setStatusIconTitle", (status) ->
	if status == true
		return "Online"
	else
		return "Offline"


UI.registerHelper "isPrivate", (room) ->
	return !room.public
