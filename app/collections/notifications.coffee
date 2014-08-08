###
File: notifations.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Notifications collection for Accidia
###

@Notifications = new Meteor.Collection('notifications')

if Meteor.isServer
	# Publish notifications
	Meteor.publish 'notifications', (notificationLimit=50) ->
		# This needs to be changed on a per user basis
		Notifications.find({user_id: @userId, hidden: false}, {sort: {time: -1}, limit: notificationLimit})
