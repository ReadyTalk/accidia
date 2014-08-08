###
File: bookmarks.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic for the templates exclusively used in the bookmarks
###

### @Globals ###

bookmarksPageDep = new Deps.Dependency


### @Template_Functions ###

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is requested.
###
Template.bookmarks.created = ->
	#set the default favicon for the app
	document.title = "Bookmarks | Accidia"

Template.bookmarks.getAllBookmarks = () ->
	Bookmarks.find({}).fetch()


Template.bookmarks.parseRoom = (msgArray) ->
	bookmarkedMessages = []
	for message in msgArray
		bookmarkedMessages.push(message)
	return bookmarkedMessages


UI.registerHelper "roomExists", (bookmark) ->
	if Rooms.findOne({_id: bookmark.room_id}) == undefined
		return false
	else
		return true

UI.registerHelper "bookmarkIsPrivateRoom", (bookmark) ->
	room = Rooms.findOne({_id: bookmark.room_id})
	if room != undefined
		return !room.public
	else
		return false


UI.registerHelper "getRoomName", (bookmark) ->
	room = Rooms.findOne({_id: bookmark.room_id})
	if room != undefined
		return room.display_name
	else
		return bookmark.room_name


### @UI_Helpers ###

UI.registerHelper "getBookmarkCount", ->
	allBookmarks = Bookmarks.find({}).fetch()
	return allBookmarks.length



### @event_handlers ###

###
@Function: hash of functions for the event handling in the chat template
@Description: Throws an event when the user scrolls to the top of the chat box
@pre: None
@post: Event handlers exist on the chat template
###
Template.bookmarks.events =
	# When you click the trashcan icon, a confirmation message appears
	"click .bookmark-remove-icon": ->
		$("#bookmark-message-#{this._id} > .row > .bookmark-page-message-time > .bookmark-remove-icon").css('display', 'none')
		$("#bookmark-message-#{this._id} > .row > .bookmark-page-message-time > .bookmark-remove-confirm").css('display', 'block')

	# Clicking the yes on the confirmation
	"click .remove-confirm-yes": ->
		Meteor.call("removeBookmark", this)

	# Clicking the no on the confirmation
	"click .remove-confirm-no": ->
		$("#bookmark-message-#{this._id} > .row > .bookmark-page-message-time > .bookmark-remove-icon").css('display', 'block')
		$("#bookmark-message-#{this._id} > .row > .bookmark-page-message-time > .bookmark-remove-confirm").css('display', 'none')

		# Meteor.call("removeBookmark", this._id)
