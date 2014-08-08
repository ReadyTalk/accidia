###
File: users_controller.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic user registration for GitHub. Also sets 'users' publication.
###


### @Globals ###

timeBeforeRemove = 10000
timeCheckRemove = 7500


### @onCreateUser ###

# creates a new user object when a user registers through GitHub. Pulls the login (handle), name, and avatar_url.
Accounts.onCreateUser (options, user) ->
	accessToken = user.services.github.accessToken
	result = Meteor.http.get("https://api.github.com/user",
		params:
			access_token: accessToken

		headers:
			"User-Agent": "ReadyTalk Chat"
	)
	throw result.error  if result.error
	profile = _.pick(result.data, "login", "name", "avatar_url")
	user.profile = profile
	user.profile.display_name = getName(result.data)
	user


### @Meteor_Methods ###

# Call using Meteor.call("function", arg1, arg2, ...)
Meteor.methods
	# Used to keep online users 'Online' on the home page
	keepOnline: ->
		now = Date.now()
		client = Meteor.user()

		# If client is null
		if client == null
			return

		# Check if users first time calling keepOnline since last visit
		if client.onlineStatus is undefined or client.onlineStatus.isOnline is false

			accessToken = client.services.github.accessToken
			result = Meteor.http.get("https://api.github.com/user",
			params:
				access_token: accessToken

			headers:
				"User-Agent": "Accidia"
			)

			Meteor.users.update(
				_id: client._id
			,
				$set:
					'profile.display_name': getName(result.data)
			)


		Meteor.users.update(
			_id: client._id
		,
			$set:
				onlineStatus:
					isOnline: true
					lastPing: now
		)



### @Intervals ###

# Removes online users who have not been online for longer than the timeBeforeRemove
removeOnlineUsers = Meteor.setInterval ( ->
	now = Date.now()
	Meteor.users.find({'onlineStatus.isOnline': true}).forEach( (user) ->
		if user.onlineStatus.lastPing < now - timeBeforeRemove
			Meteor.users.update({_id: user._id}, {$set: {onlineStatus: {isOnline: false, lastPing: null}}})
	)
), timeCheckRemove


### @Miscellaneous_Functions ###


###
@Function: getName
@Description: Gets the display name for a user
@params: data object from GitHub
@return: string for the display name
@pre: None
@post: None
###
getName = (data) ->
		if data.name != "" and data.name != null and data.name != undefined and /\S/.test(data.name)
			data.name
		else
			data.login
