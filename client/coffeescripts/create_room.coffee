###
File: create_room.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic for the templates exclusively used in the create room page
###



### @Globals ###

# object to pass to create_room function
room = {}
room.public = true

roomPublicDep = new Deps.Dependency

#Array of users to be invited to a private room
room.invitedUsers = []

#the dependency for the messages template to force update
getUsers = null
getUsersDep = new Deps.Dependency

# boolean to tell if all users have been invited or not
allUsersInvitedBoolean = false

# dependency for update invite all icon
allUsersInvitedBooleanDep = new Deps.Dependency

data = null


### @Template_Functions ###

###
@Function: sortUsers
@Description: Returns an array of all users, sorted first by online status, then sub-sorted alphabetically.
@params: None
@return: Array of sorted user objects
@pre: Called within the template named home_loggedIn
@post: None
###
Template.invite_users.sortUsers = ->
	getUsersDep.depend()
	allOnlineUsers = Meteor.users.find({"onlineStatus.isOnline": true}).fetch()
	allOfflineUsers = Meteor.users.find({"onlineStatus.isOnline": false}).fetch()

	allOnlineUsers.sort((user1, user2) ->
		return getName(user1).toLowerCase().localeCompare(getName(user2).toLowerCase())
	)

	allOfflineUsers.sort((user1, user2) ->
		return getName(user1).toLowerCase().localeCompare(getName(user2).toLowerCase())
	)

	sortedArray = allOnlineUsers.concat(allOfflineUsers)

	# Remove self from users to show that can be invited
	i = 0
	meIndex = null
	for user in sortedArray
		if user._id is Meteor.user()._id
			meIndex = i
			break
		i++

	if meIndex != null
		sortedArray.splice(meIndex, 1)

	sortedArray

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is requested.
###
Template.create_room.created = ->
	document.title = "Create Room | Accidia"
	room.invitedUsers = []
	room.public = true
	roomPublicDep.changed()
	data = @data




### @Event_Handlers ###

###
@Function: hash of functions for the event handling in the create_room template
@Description: Takes either a button click or an Enter
			key input and calls the createRoom function
@pre: None
@post: Event handlers exist on the create_room template
###
Template.create_room.events =
	#create room on enter key or button click
	"click input#public-checkbox": (event) ->
		room.public = true
		roomPublicDep.changed()
	"click input#private-checkbox": (event) ->
		room.public = false
		roomPublicDep.changed()

	"keydown input#new-room-name": (event) ->
		if event.which is 13
			createRoom()
			event.preventDefault()
	"click button#create-room-button": ->
		createRoom()
		event.preventDefault()

	"click button#final-invite-button": ->
		$('#inviteModal').modal('toggle')
		event.preventDefault()
		$('#users-invited-message').css('display', 'block')
	"click #invite-single-user": ->
		# Add user to invited users Array
		if room.invitedUsers.indexOf(this._id) == -1
			room.invitedUsers.push(this._id)
		getUsersDep.changed()
	"click #remove-single-user": ->
		# Remove user from invited users Array
		indexOfUser = room.invitedUsers.indexOf(this._id)
		room.invitedUsers.splice(indexOfUser, 1)
		getUsersDep.changed()
	"click #invite-all": ->
		inviteAllUsers(true)
		allUsersInvitedBoolean = true
		allUsersInvitedBooleanDep.changed()
		getUsersDep.changed()
	"click #remove-all": ->
		inviteAllUsers(false)
		allUsersInvitedBoolean = false
		allUsersInvitedBooleanDep.changed()
		getUsersDep.changed()



### @UI_Helpers ###

###
@Function: allUsersInvited
@Description: helper to swap the invite all icon
@params: none
@return: boolean
@pre: none
@post: none
###
UI.registerHelper "allUsersInvited", () ->
	allUsersInvitedBooleanDep.depend()
	return allUsersInvitedBoolean

###
@Function: isInvited
@Description: returns whether or not a user is in the invitedUsers Array
@params: user object
@return: true or false
@pre: Can only be called in handlebars.
@post:
###
UI.registerHelper "isInvited", (user) ->
	# Check if userID is in invitedUsers Array
	if user._id in room.invitedUsers
		return false
	else
		return true

UI.registerHelper 'createInviteUsers', () ->
	roomPublicDep.depend()
	return !room.public



### @Miscellaneous_Functions ###

###
@Function: createRoom
@Description: Grabs text from input field and checks to see if it is a valid room name.
			If valid, calls a function to insert the new room into the database. If not,
			flashes an error message to the user.
@params: None
@return: None
@pre: None
@post: If the room is valid, the room is inserted into the database, and the user is redirected
		to the room.
###
createRoom = ->
	FlashMessages.clear()
	room.name = document.getElementById("new-room-name").value
	room.invitedUsers.push(Meteor.user()._id)

	Meteor.call('insertRoom', room,  (err, result) ->

		if err == undefined
			Router.go('chat', {room_name: result})
		else if err.error == 102
			FlashMessages.sendError("The room name cannot only contain whitespace and special characters", {autoHide: false})
		else if err.error == 101
			FlashMessages.sendError("There is already a room with this name", { autoHide: false })
		else
			console.log err
	)


###
@Function: getName
@Description: A replication of the server side getName to parse between username and real name
@params: user object
@return: string representing the user's display name
@pre: None
@post: message from input box is inserted into the database
###
getName = (user) ->
	if user.profile.name != "" and user.profile.name != null and user.profile.name != undefined
		user.profile.name
	else
		user.profile.login

###
@Function: inviteAllUsers
@Description: Adds or removes all available users
@params: boolean
@return: None
@pre: None
@post: Users are removed or added from/to array
###
inviteAllUsers = (add) ->
	if add
		for user in Meteor.users.find({}).fetch()
			if room.invitedUsers.indexOf(user._id) == -1
				room.invitedUsers.push(user._id)
	else
		room.invitedUsers = []