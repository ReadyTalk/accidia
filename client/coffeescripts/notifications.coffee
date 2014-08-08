notificationLimit = null
notificationDiv = null
Template.notifications.created = ->
  #setting chat page meta data
  document.title = "Notifications | Accidia"
  notificationLimit = 50
  Session.set("notificationLimit", notificationLimit)


Template.notifications.rendered = ->
	notificationDiv = document.querySelector(".content")

###
@Function: getNotifications
@Description: Returns all notifications in time order
@params: None
@return: a cursor on the Notifications collection
@pre: called within the notification_modal template
@post: None
###
Template.notifications.getNotifications = ->
	x = Notifications.find({}, {sort: {time: -1}})
	if notificationLimit == null
		notificationLimit = 50
	Session.set("notificationsLimit", notificationLimit++)
	return x

Template.notifications.events
	"click #notification-remove-icon": ->
		Meteor.call("removeSingleNotification", this._id)
	"click #notification-remove-all": ->
		Meteor.call("removeAllNotifications", Meteor.user()._id)
	"scroll .content": ->
		if notificationDiv.scrollTop + notificationDiv.offsetHeight >= notificationDiv.scrollHeight
			notificationLimit += 25
			Session.set("notificationLimit", notificationLimit)


### @Dependencies ###

Deps.autorun () ->
	notifcationLimit = Session.get('notificationLimit')
	sub = Meteor.subscribe('notifications', notificationLimit)



UI.registerHelper "getPic", (user) ->
  user.profile.avatar_url