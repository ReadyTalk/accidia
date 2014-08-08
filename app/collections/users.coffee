###
File: users.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Meteor.users collection for Accidia
###



if Meteor.isServer

	# publishes profile object and onlineStatus.isOnline attributes of all users in the Users collection
	Meteor.publish 'users', () ->
		Meteor.users.find({}, {fields: {profile: 1, 'onlineStatus.isOnline': 1}})

	# publishes a user's new_notification_count to only themselves
	Meteor.publish 'usersNoteCount', () ->
		Meteor.users.find({_id: @userId}, {fields: {new_notification_count: 1}})