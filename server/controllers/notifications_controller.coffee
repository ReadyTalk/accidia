###
File: notifications_controller.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Definitions for server-side logic, including Meteor methods, intervals, and miscellaneous functions.
###



### @Meteor_Methods ###

# Call using Meteor.call("function", arg1, arg2, ...)
Meteor.methods
	# This will insert a notication for the user to see in the notications modal
	insertNotification: (note) ->
		Notifications.insert
			user_id: note.user_id
			type: note.type
			room_name: note.room_name
			message: note.message
			hidden: false
			seen: false
			time: Date.now()

	# This will set a notication to be hidden after it has been viewed by a user
	removeSingleNotification: (noteId) ->
		Notifications.remove({_id: noteId })

	# Removes all of a users notification
	removeAllNotifications: (user) ->
		Notifications.remove({user_id: user})

	# Sets all a users notifications as seen
	setNotificationsAsSeen: () ->
		client_id = Meteor.user()._id

		notifications = Notifications.find({user_id: client_id, seen: false}).fetch()
		for notification in notifications
			Notifications.update({"_id": notification._id}, {$set: {"seen": true}})




