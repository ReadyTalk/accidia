###
File: chat_controller.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Definitions for server-side logic, including Meteor methods, intervals, and miscellaneous functions.
###



### @Globals ###

timeBeforeRemove = 10000
timeCheckRemove = 5000
userEntered = " has entered the room."
userLeft = " has left the room."
sysMsgDuration = 900000

# The to-be constructed notification to send to the notification controller
note = {}

room_id = null


### @Meteor_Methods ###

# Call using Meteor.call("function", arg1, arg2, ...)
Meteor.methods
	# Insert messages into the database properly
	insertMsg: (message, room, type, name) ->
		message = alterMessage(message, room)
		client = Meteor.user()

		if type == 'system_message'
			client = "System"

		if client == null
			client = 'System'

		if name == null or name == undefined
			name = client.profile.display_name

		if type == 'user_message'
			if Messages.findOne({room: room}) == undefined
				msgIndex = 0
			else
				msgIndex = Messages.findOne({room: room}, {sort: {index: -1}}).index + 1



		Messages.insert
			name: name
			message: message
			time: Date.now()
			type: type
			room: room
			index: msgIndex
			loginName: if client != "System" then client.profile.login else "System"
			pictureURL: if client != "System" then client.profile.avatar_url else "System"

		if type == 'user_message'
			for userLoop in Rooms.findOne({_id: room}).active_users
				Rooms.update({_id: room, 'active_users.user._id': userLoop.user._id }, {$inc: {'active_users.$.maxMessages': 1}})



	# Used to keep our users 'alive' in a chat room
	keepAlive: (roomName, roomId, client) ->
		now = Date.now()
		if client == null or client == undefined
			client = Meteor.user()
			finalClient = {}
			finalClient.profile = client.profile
			finalClient._id = client._id
			if client == null
				return

		if !userInArray(Rooms.findOne({room_name: roomName}).active_users, finalClient)
			# Insert new user into active users array for the specific room
			Rooms.update({room_name: roomName}, {$push: {active_users: {user: finalClient, last_seen: now, maxMessages: 25}}})
			Meteor.call("insertMsg", client.profile.display_name + userEntered, roomId, "system_message", "System")
		else
			# Update each user's last seen time.
			Rooms.update({room_name: roomName, 'active_users.user._id': finalClient._id}, {$set: {'active_users.$.last_seen': now}}) if finalClient


	# Takes in a user-inputted room name and checks if the sanitized room name already exists.
	# Returns an error if it already exists, else creates the new room.
	insertRoom: (room) ->
		finalRoomName = Meteor.call('createRoomName', room.name)

		if finalRoomName == ""
			throw new Meteor.Error(102, "Room name must contain more than whitespace and special characters")

		if Rooms.findOne({room_name: finalRoomName}) != undefined
			throw new Meteor.Error(101, "Room name already exists", finalRoomName)

		if room.public
			Rooms.insert
				active_users: []
				display_name: room.name
				room_name: finalRoomName
				owner: Meteor.user()
				public: room.public
		else
			room_id = Rooms.insert
				active_users: []
				display_name: room.name
				room_name: finalRoomName
				owner: Meteor.user()
				public: room.public
				allowed_users: room.invitedUsers

		if room.public is false
			for user in room.invitedUsers
				if user != Meteor.user()._id
					note.user_id = user
					note.type = 'invite'
					note.room_name = finalRoomName
					note.message = {}
					note.message.room_id = room_id
					note.message.room_display_name = room.name
					note.message.message = Meteor.user().profile.login + ' has invited you to '
					note.message.sender = Meteor.user().profile
					Meteor.call('insertNotification', note)

		return finalRoomName

	# Deletes the room with the specified id
	deleteRoom: (roomID) ->
		room = Rooms.findOne({_id: roomID})

		if Meteor.user()._id == room.owner._id
			Rooms.remove({_id: roomID})
			Messages.remove({room: roomID})
			Notifications.remove({"message.room_id": roomID})
		else
			return


	# Sanitizes a room name of special characters
	createRoomName: (roomName) ->
		ret = roomName.toLowerCase()
		ret = ret.replace(/[^\w\s]|_/g, "").replace(/\s+/g, "")
		return ret

	# Add user to allowed users list
	addAllowedUser: (roomName, uID) ->
		Rooms.update({room_name: roomName}, {$push: {allowed_users: uID}})

	# Remove user from allowed users list
	removeAllowedUser: (roomName, uID) ->
		Rooms.update({room_name: roomName}, {$pull: {allowed_users: uID}})

	# Sets the allowed users list
	setAllowedUsers: (roomName, uIDs) ->

		room = Rooms.findOne({room_name: roomName})
		roomDisplayName = room.display_name
		currentUsers = room.allowed_users
		roomID = room._id

		for user in uIDs
			if user not in currentUsers
				note.user_id = user
				note.type = 'invite'
				note.room_name = room.room_name
				note.message = {}
				note.message.room_id = roomID
				note.message.room_display_name = roomDisplayName
				note.message.message = Meteor.user().profile.login + ' has invited you to '
				note.message.sender = Meteor.user().profile
				Meteor.call('insertNotification', note)

		Rooms.update({room_name: roomName}, {$set: {allowed_users: uIDs}})



### @Intervals ###

# Removes active users in a chat room after set amount of time
removeActiveUsers = Meteor.setInterval ( ->
	# Loop through every room in the Rooms collection
	Rooms.find({}).forEach( (room) ->
		# Reset users in activeUsers list
		allActiveUsers = undefined
		# Get every active user for the given chat room
		allActiveUsers =  Rooms.findOne({room_name: room.room_name}).active_users
		# Next few lines will just insert system messages into the database so we can alter users that people left
		if allActiveUsers != undefined
			allActiveUsers.forEach (user) ->
				if user.last_seen < Date.now() - timeBeforeRemove
					Meteor.call("insertMsg", user.user.profile.display_name + userLeft, room._id, "system_message" , "System")
		Rooms.update({room_name: room.room_name}, {$pull: {active_users: {last_seen: {$lt: (Date.now() - timeBeforeRemove)}}}})

		)
), timeCheckRemove

#removes system messages older than 15 mins, ever 15 mins
removeSystemMessages = Meteor.setInterval ( ->
	Messages.remove({type: "system_message", time: {$lt: (Date.now() - sysMsgDuration)}})
), sysMsgDuration



### @Miscellaneous_Functions ###

###
@Function: userInArray
@Description: Checks to see if a specified user is in the active users array
@params: Array of user objects, user object
@return: bool indicating whether a user is in the array
@pre: None
@post: None
###
userInArray = (array, user) ->
	i = 0
	inList = false

	while i < array.length
		if array[i].user._id == user._id
			inList = true
			break
		i++

	return inList


alterMessage = (message, room_id) ->
	message = constructMentions(message, room_id)
	message = renderImage(message)
	return message


renderImage = (message) ->
	matches = message.match(/\b(http:\/\/|https:\/\/)\S+(\.jpg|\.jpeg|\.gif|\.png|\.svg|\.bmp|\.JPG|\.JPEG|\.GIF|\.PNG|\.SVG|\.BMP)\b/g)
	if matches == null
		return message
	for match in matches
		re = new RegExp(match, 'g')
		message = message.replace(re, "![Image not found at "  + match + "](" + match + ")")
		return message

constructMentions = (message, room_id) ->
	matches = message.match(/(@\w+\-?\w*)/g)
	retMessage = message
	if matches == null
		return retMessage
	else
		room = Rooms.findOne({"_id": room_id})
		users = []

		for user in matches
			note = {}
			note.message = {}
			matchedUser = user.substring(1, user.length)
			matchedUser = Meteor.users.findOne({'profile.login': matchedUser})




			if matchedUser != undefined
				note.user_id = matchedUser._id
				if users.indexOf(note.user_id) == -1
					# Bold mentions
					find = user
					re = new RegExp(find, 'g')

					retMessage = retMessage.replace(re, "**" + user + "**")

					note.room_name = room.room_name
					note.type = "mention"
					note.message.room_id = room_id
					note.message.room_display_name = room.display_name
					note.message.message = message
					note.message.sender = Meteor.user().profile
					users.push(note.user_id)
					Meteor.call('insertNotification', note)

	return retMessage
