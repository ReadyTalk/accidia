###
File: rooms.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Rooms collection for ReadyTalk Chat
###

@Rooms = new Meteor.Collection('rooms')

if Meteor.isServer

	# Publishes display_name, room_name, and active_users.user.profile attributes of all rooms in the Rooms collection
	Meteor.publish 'rooms', ->
		Rooms.find({$or: [{public: true}, {'allowed_users': @userId}]}, {fields: {_id: 1, owner: 1, display_name: 1, room_name: 1, "active_users.user.profile": 1, public: 1, allowed_users: 1, _id: 1}})
