###
File: layout.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic for the templates exclusively used in the layout
###



### @Globals ###

# bool indicating if the user is on any page
isOnline = null
allBookmarks = null

# bool indicating whether or not to add the sidebar
enableSidebar = true

data = null

# div for notification modal
notificationDiv = null

# number of notifications to show up on notification modal load
notificationLimit = null

### @Template_Functions ###

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is requested.
###
Template.header.created = ->
	#set the default favicon for the app
	link = document.createElement("link")
	link.rel = "icon"
	link.href = '/favicon.ico'
	link.sizes = "16x16 32x32"
	document.getElementsByTagName("head")[0].appendChild link


###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is ready to be viewed.
###
Template.notYou.rendered = ->
	#sets up content that appears on click of the 'Not you' dropdown option
	title = '<span><font size="4"><strong>Not you?</strong></font></span>'+ '<button type="button" id="close" class="close" onclick="$(&quot;.notYou&quot;).popover(&quot;hide&quot;);$(&quot;.popover&quot;).remove();">&times;</button>'
	body = '<p>If you are trying to login as a different user, you must follow one of the below steps.</p>' +
	'<span><strong>Log out of Github</strong></span><p>Go to <a href="http://www.github.com">Github</a> and logout there. Then return here and try to login again with your credentials.</p>' +
	'<span><strong>Open a private browsing tab</strong></span><p>Open a private browsing tab and return to the site and log in normally. Your session will not persist, but will allow you to login as a different user without logging out on Github.</p>'

	# Set not you popver values as well as how it is triggered
	$(".notYou").popover
		trigger: 'click'
		html: true
		title: title
		content: body
		animation: true

	# jQuery for whenver a user clicks on anything that isnt a popover, popovers disappear
	$("body").on "click", (e) ->
	  	$(".notYou").each ->

	    	#the 'is' for buttons that trigger popups
	    	#the 'has' for icons within a button that triggers a popup
	    	$(this).popover "hide"  if not $(this).is(e.target) and $(this).has(e.target).length is 0 and $(".popover").has(e.target).length is 0
	    	if not $(this).is(e.target) and $(this).has(e.target).length is 0 and $(".popover").has(e.target).length is 0
	    		$(this).popover "hide"
	    		$(".popover").remove()

	return

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is requested.
###
Template.user_logged_in.created = ->
	#starts interval for updating a user's online status
	isOnline = Meteor.setInterval ( ->
		Meteor.call('keepOnline')
		return
	), 5000

	data = @data
	Session.set('notificationLimit', 50)

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is destroyed.
###
Template.user_logged_in.destroyed = ->
	#clears the interval for updating a user's online status
	Meteor.clearInterval(isOnline)

###
@Function: getAvailableRooms
@Description: Sorts rooms based off of room name in lexicographical order
@params: None
@return: a cursor on the rooms collection
@pre: called within the global_rooms_available template
@post: None
###
Template.available_rooms_stretch.getAvailableRooms = ->
  Rooms.find({}, {sort: {room_name: 1}})

###
@Function: sortUsers
@Description: Returns an array of all users, sorted first by online status, then sub-sorted alphabetically.
@params: None
@return: Array of sorted user objects
@pre: Called within the template named home_logged_in
@post: None
###
Template.all_users.sortUsers = ->
	allOnlineUsers = Meteor.users.find({"onlineStatus.isOnline": true}).fetch()
	allOfflineUsers = Meteor.users.find({"onlineStatus.isOnline": false}).fetch()

	allOnlineUsers.sort((user1, user2) ->
		return user1.profile.display_name.toLowerCase().localeCompare(user2.profile.display_name.toLowerCase())
	)

	allOfflineUsers.sort((user1, user2) ->
		return user1.profile.display_name.toLowerCase().localeCompare(user2.profile.display_name.toLowerCase())
	)

	sortedArray = allOnlineUsers.concat(allOfflineUsers)

###
@Function: getFirstFiveNotifications
@Description: Returns first five notifications in time order
@params: None
@return: a cursor on the Notifications collection
@pre: called within the user_logged_in template
@post: None
###
Template.user_logged_in.getFirstFiveNotifications = ->
	allNotes = Notifications.find({}, {sort: {time: -1}}).fetch()
	firstFiveNotes = []
	for i in [0...5]
		if allNotes[i] is null or allNotes[i] is undefined
			break
		else
			firstFiveNotes.push(allNotes[i])
			if firstFiveNotes[i].message.message.length > 35
				firstFiveNotes[i].message.message = firstFiveNotes[i].message.message.substring(0,34)
				firstFiveNotes[i].message.message += "..."
	firstFiveNotes


### @Event_Handlers ###

###
@Function: hash of functions for the event handling in the user_logged_in template
@Description: Logs user out on click of 'Logout' dropdown option
@pre: User must be logged in
@post: Event handlers exist on the user_logged_in template
###
Template.user_logged_in.events
	"click #layout-header-dropdown-logout": (e, tmpl) ->
		Meteor.logout (err) ->
			if err
				console.log("Where do you think you're going?")
			else
				return
	'click .sidebar-toggle': (e) ->
		e.preventDefault()

		#If window is small enough, enable sidebar push menu
		if ($(window).width() <= 992)
			$('.row-offcanvas').toggleClass('active')
			$('.left-side').removeClass("collapse-left")
			$('.left-side').removeClass("collapse-right")
			$(".middle").removeClass("strech")
			$('.row-offcanvas').toggleClass("relative")
		else
			#Else, enable content streching
			$('.left-side').toggleClass("collapse-left")
			$('.right-side').toggleClass("collapse-right")
			$(".middle").toggleClass("strech")

	"click .messages-menu > .dropdown-toggle": ->
		Meteor.call("setNotificationsAsSeen")

Template.all_users.events
	"click #home-invite-to-one-on-one": ->
		room = {}
		room.public = false

		# Makes sure you cannot make a room with yourself. Pervert.
		if this.profile.login != Meteor.user().profile.login
			if this.profile.login < Meteor.user().profile.login
				room.name = this.profile.login + " & " + Meteor.user().profile.login
			else
				room.name = Meteor.user().profile.login + " & " + this.profile.login

			room.invitedUsers = [this._id, Meteor.user()._id]
			Meteor.call("insertRoom", room, (err, result) ->
				if err == undefined
					Router.go('chat', {room_name: result})
				else if err.error = 101
					Router.go('chat', {room_name: err.details})
				else
					console.log err
				)


### @UI_Helpers ###


UI.registerHelper "hasNewNotifications", ->
	if Notifications.find({user_id: Meteor.user()._id, seen: false}).fetch().length > 0
		true
	else
		false

UI.registerHelper "getUnseenNotificationsCount", ->
	noteCount = Notifications.find({user_id: Meteor.user()._id, seen: false}).fetch().length
	if noteCount > 50
		return "50+"
	else
		noteCount

UI.registerHelper "hasBookmarks", () ->
	if Bookmarks.find({}).fetch().length is 0
		return false
	else
		return true

UI.registerHelper "isInvite", () ->
	if this.type == "invite"
		return true
	else
		return false

UI.registerHelper "isMention", () ->
	if this.type == "mention"
		return true
	else
		return false

UI.registerHelper "userHasAccessToRoom", () ->
	user_id = Meteor.user()._id
	room_id = this.message.room_id
	room = Rooms.findOne({"_id": room_id})
	if room == undefined
		return false
	else
		return true


###
@Function: hasVisibleNotifications
@Description: helper to tell whether the current user has visible (not hidden) notifications
@params: none
@return: boolean
@pre: none
@post: none
###
UI.registerHelper "hasNoVisibleNotifications", () ->
	if Notifications.findOne({}) == undefined
			return true
		else
			return false

###
@Function: getTitle
@Description: returns the type of a notification
@params: notification.type
@return: string
@pre: none
@post: none
###
UI.registerHelper "getTitle", (type) ->
	return type.charAt(0).toUpperCase() + type.slice(1);


