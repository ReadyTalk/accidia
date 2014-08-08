###
File: bookmarks.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Bookmarks collection for ReadyTalk Chat
###

@Bookmarks = new Meteor.Collection('bookmarks')

if Meteor.isServer
	# Publish bookmarks
	Meteor.publish 'bookmarks', (room = 'all') ->
		# This needs to be changed on a per user basis
		if room == 'all'
			Bookmarks.find({user_id: @userId})
		else
			roomDoc = Rooms.findOne({room_name: room})
			if roomDoc != undefined
				roomId = roomDoc._id
				Bookmarks.find({user_id: @userId, room_id: roomId})
