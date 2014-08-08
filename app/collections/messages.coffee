###
File: messages.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Messages collection for ReadyTalk Chat
###

@Messages = new Meteor.Collection('messages')

if Meteor.isServer

	#duration system messages will display in chat (15 Minutes)
	sysMsgDuration = 900000

	Meteor.publish 'system_messages', (roomName) ->
		roomDoc = Rooms.findOne({room_name: roomName})
		if roomDoc != undefined
			roomId = roomDoc._id
			Messages.find({room: roomId, type: "system_message", time: {$gt: (Date.now() - sysMsgDuration)}}, {fields: {_id: 1, name: 1, message: 1, room: 1, time: 1, type: 1}})

	# New user_message publication
	Meteor.publish 'user_messages', (roomId, messageIndex) ->
		lastMessage = Messages.findOne({room: roomId, type: 'user_message'}, {sort: {index: -1}})

		maxIndex = (if lastMessage then lastMessage.index else 0)
		messageIndex = (if messageIndex != null  then messageIndex else maxIndex - 25)

		Messages.find({room: roomId, index: {$gt: messageIndex}}, {fields: {_id: 1, name: 1, message: 1, room: 1, time: 1, type: 1, index: 1}})
