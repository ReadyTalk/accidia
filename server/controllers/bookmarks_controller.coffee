###
File: bookmarks_controller.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Definitions for server-side logic, including Meteor methods, intervals, and miscellaneous functions.
###


### @Meteor_Methods ###

# Call using Meteor.call("function", arg1, arg2, ...)
Meteor.methods
	# Add a bookmark to a users total list of bookmarks
	insertBookmark: (message, roomId) ->

		messageObj = {}
		messageObj.message = message.message
		messageObj.room = message.room
		messageObj.time = message.time
		messageObj.name = message.name
		messageObj._id = message._id
		roomName = Rooms.findOne({_id: messageObj.room}).display_name

		userId = Meteor.user()._id
		if Bookmarks.findOne(
  			room_id: roomId
  			user_id: userId) is `undefined`
			# create new boomark document with initial bookmark
			Bookmarks.insert
				room_id: roomId
				user_id: userId
				room_name: roomName
				messages: [messageObj]
		else
			Bookmarks.update
				room_id: roomId
				room_name: roomName
				user_id: userId
			,
				$push:
					messages: messageObj

		# Increment the number of people who have bookmarked a message
		# This will be useful late if we decided to add the ability to delete rooms, but don't want to delete a users
		# bookmarked messages from that room.
		Messages.update({_id: messageObj._id}, {$inc: {bm_count: 1}})

	# Removes a bookmark for the list of bookmarks for a given user
	removeBookmark: (message) ->
		messageObj = {}
		messageObj.message = message.message
		messageObj.room = message.room
		messageObj.time = message.time
		messageObj.name = message.name
		messageObj._id = message._id
		userId = Meteor.user()._id

		# Gets the roomId of where the message is attached
		message = Messages.findOne({_id: messageObj._id})
		if message != undefined
			roomId = message.room

			Bookmarks.update({room_id: roomId, user_id: userId}, {$pull: {messages: messageObj}})

			if Bookmarks.findOne({room_id: roomId, user_id: userId}).messages.length == 0
				Bookmarks.remove({room_id: roomId, user_id: userId})
		else
			bookmark = Bookmarks.findOne({room_id: messageObj.room})
			Bookmarks.update({room_name: bookmark.room_name, user_id: userId}, {$pull: {messages: messageObj}})
			if Bookmarks.findOne({room_name: bookmark.room_name, user_id: userId}).messages.length == 0
				Bookmarks.remove({room_name: bookmark.room_name, user_id: userId})
			

		# Decrement the number of users that have bookmarked a message by one
		Messages.update({_id: messageObj._id}, {$inc: {bm_count: -1}})
