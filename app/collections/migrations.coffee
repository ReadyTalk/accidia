###
File: migrations.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: This file will be where we house our database migrations. If you build these migrations properly
            they should only run once. It will be useful to keep track of our migrations for reference.
###

# Collection to hold our migrations
@Migrations = new Meteor.Collection('migrations');

Meteor.startup ->
  # Migration to tie all messages to room id instead of room name. This will make editing room names in the future much easier.
	if Meteor.isServer
		unless Migrations.findOne(name: "messagesRoomToId")
			for rm in Rooms.find({}).fetch()
				Messages.update({room: rm.room_name}, {$set: {room: rm._id}}, {multi: true})
			Migrations.insert(name: "messagesRoomToId")

		unless Migrations.findOne(name: "messagesAddIndex")
			for rm in Rooms.find({}).fetch()
				i = 1
				for msg in Messages.find({room: rm._id, type: 'user_message'}, {sort: {time: 1}}).fetch()
					Messages.update({_id: msg._id}, {$set: {index: i}})
					i++
			Migrations.insert(name: "messagesAddIndex")




