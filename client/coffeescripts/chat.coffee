###
File: chat.coffee
Authors: ReadyTalk Engineering Intern Team 2014
Description: Logic for the templates exclusively used in the chat pages as well as functions and UI (formerly Handlebar) helpers.
###



### @Globals ###

#subscription for the messages collection
sub = null

#the message to fill input box on empty
message = ""

#The name of the current room
room_Name = null

#a bool indicating if the user is on the page
isOnPage = null

#bool indicating if the title should be flahsed
flashingTitle = null

#bool to represent if messages was updated
updateMsgs = null

#person sending message
name = null

# current sender of message
currentSender = null

# last sender
lastSender = null

#assume user will focus tab on load
document.active = true

#original title of page
original = null

currentRoomId = null

#message counts
oldMessageCount = null
newMessageCount = null

#Indicates message first load
getFirstMessageCount = true

#The title to flash
flashTitle = "New Messages!"

#The title is currently on flash
flashBool = false

#the Chat box
chatDiv = null

#the value that will tell our subscribe how far back to pull messages from
firstMessageIndex = 0

#bool representing if the user is at the bottom of chatbox
document.bottomCheck = null

#the favicons for flashing titles NEEDS TO BE UPDATED
greenFavicon = null
blueFavicon = null

#indicates if a message update was forced
forcedUpdate = false

#the scroll height before more messages are loaded
oldScrollHeight = null

firstPageLoad = true

#bool representing if user is at the top of chat div
document.topCheck = false

#random ints to be incremented to force message updates
scroll = 0
hitTop = 0
scrollTopChild = null

# Kyles stuff
emoticonSender = null
#

currentTime = null
lastTime = null
currentColor = null

sameSender = false

data = null
#
allowedUsers = []
getUsersDep = new Deps.Dependency

# The array of sorted users based on their online status
sortedUsersArray = []

### @Template_Functions ###

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is ready to be viewed.
###
Template.chat.rendered = ->
  #grab chat box now that page is loaded
  chatDiv = document.querySelector(".chat-messages-container")
  #scroll to the bottom on page load
  Session.set("newFirstMessageIndex", firstMessageIndex)
  document.gettingMoreMessages = false

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables to be ran/assigned when the document is requested.
###
Template.chat.created = ->
  #setting chat page meta data
  document.title = @data.display_name + " | Accidia"
  original = document.title
  room_Name = @data.room_name
  window.name = @data.display_name
  data = @data
  Session.set('currentRoomId', data._id)
  Session.set('newFirstMessageIndex', null)
  firstMessageIndex = null
  Meteor.call('keepAlive', data.room_name, data._id)

  #set up the user heartbeat to run as soon as they are on the page.
  isOnPage = Meteor.setInterval ( ->
    Meteor.call('keepAlive', data.room_name, data._id)
    return
  ), 2000

  #set up the flashing title interval if there is a new message
  flashingTitle = Meteor.setInterval ( ->
    if document.active == false and flashBool == true
      if document.title == original
        document.title = flashTitle
        setFavicon(blueFavicon)
      else
        document.title = original
        setFavicon(greenFavicon)
    return
  ), 1500

  #make focus and blur events
  createEventHandles()
  return

###
@Function: Predefined function by Meteor.
@Description: A set of functions and variables that are set to be ran/assigned when the document is destroyed.
###
Template.chat.destroyed = ->

  #stop saying user is on page
  Meteor.clearInterval(isOnPage)
  #stop flashing title if new message arrives
  Meteor.clearInterval(flashingTitle)
  #remove the perodic message update
  Meteor.clearInterval(updateMsgs)
  #remove focus and blur events
  destroyEventHandles()

  $('#notification-modal').modal('hide');
  $('#bookmark-modal').modal('hide');
  $('body').removeClass('modal-open');
  $('.modal-backdrop').remove();
  firstMessageIndex = null
  Session.set("newFirstMessageIndex", null)

  return

###
@Function: sortUsers
@Description: Returns an array of all users, sorted first by online status, then sub-sorted alphabetically.
@params: None
@return: Array of sorted user objects
@pre: Called within the template named home_loggedIn
@post: None
###
Template.inChat_invite_modal.sortUsers = ->
  getUsersDep.depend()

  allOnlineUsers = Meteor.users.find({"onlineStatus.isOnline": true}).fetch()
  allOfflineUsers = Meteor.users.find({"onlineStatus.isOnline": false}).fetch()

  allOnlineUsers.sort((user1, user2) ->
    return user1.profile.display_name.toLowerCase().localeCompare(user2.profile.display_name.toLowerCase())
  )

  allOfflineUsers.sort((user1, user2) ->
    return user1.profile.display_name.toLowerCase().localeCompare(user2.profile.display_name.toLowerCase())
  )

  sortedUsersArray = allOnlineUsers.concat(allOfflineUsers)

  # Remove self from users to show that can be invited
  i = 0
  meIndex = null
  for user in sortedUsersArray
    if user._id is Meteor.user()._id
      meIndex = i
      break
    i++

  if meIndex != null
    sortedUsersArray.splice(meIndex, 1)

  sortedUsersArray


Template.msg.rendered = ->
  setScrollToBottom() if document.bottomCheck
  if document.topCheck
    this.autorun(() ->
      if this.domrange.members[0].id == "chat-message-scroll-1"
        document.progressiveRenderCount = 24
      else
        document.progressiveRenderCount++
      if document.progressiveRenderCount >= 24
        $(chatDiv).waitForImages ->
          chatDiv.scrollTop = scrollTopChild.offsetTop - scrollTopChild.scrollHeight
          document.topCheck = false
          document.gettingMoreMessages = false
          document.progressiveRenderCount = 0
    )


###
@Function: getMessages
@Description: Sorts messages in descending order based on time.
@params: None
@return: Array of message objects up to message limit
@pre: Called within the template named messages
@post: Message is increased by one
###
# NEEDS TO BE REWORKED FOR PERFORMACE AT SOME POINT! WAY TOO PERFORMANCE INTENSIVE FOR HIGH MESSAGE COUNT
Template.messages.getMessages = ->
  #see if user is at bottom of chat box.
  document.bottomCheck = false
  if null != chatDiv and chatDiv.scrollTop + chatDiv.offsetHeight >= chatDiv.scrollHeight
    document.bottomCheck = true

  # Msg Properties
  colorIndex = 0
  lastfrom = null
  me = null
  newMessageCount = 0

  # Color Variables
  hyperlinkBlue = "#3385FF"
  gray = "#9a9a9a"
  lightGray = "#f2f2f2"
  lightRed = "#FDDDDD"
  lightGreen = "#DDFFDD"
  darkRed = "#990033"
  darkGreen = "#4AAB4A"
  white = "#FFFFFF"
  lightBlue = "#E6F2FF"
  pink = "#FF66FF"
  black333 = "#333"
  systemBlue = "#EEF5FB"
  readyTalkGreen = "#6ebe47"
  green = "#A8D891"
  red = "#B63E64"
  borderNone = "none"
  arrayOfColors = ["#FF0000", "#FF7A00", "#48ff00", "#00ff00", "#00ff7A", "#00ffF4", "#003Dff", "#8500ff", "#ff00b7"]

  #query db for messages in proper order
  allMessages = Messages.find({}, {sort: {time: -1 }}).fetch()
  allMessages.reverse()

  #set current users count
  newMessageCount = allMessages.length

  #get the number of messages on first load
  if getFirstMessageCount == true
    oldMessageCount = newMessageCount
    getFirstMessageCount = false

  #check to see if notification flash should start
  if oldMessageCount < newMessageCount and document.active == false and allMessages[newMessageCount-1].type != "system_message"
    flashBool = true

  #update current count
  oldMessageCount = newMessageCount

  #set background color for messages belonging to other users
  for message in allMessages

    sameSender = false
    sameTime = false
  # Changes background color of messages.
    if not(undefined == message or null == message)
      # If the message is a system message, if a leave, the background is red. If a join, background is green
      if message.type == 'system_message'
        if message.message.indexOf('left') >= 0
          message.backgroundColor = lightRed
          message.borderColor = red
        else if message.message.indexOf('entered') >= 0
          message.backgroundColor = lightGreen
          message.borderColor = green
        message.textColor = gray
        sameSender = false

      # If the message is a user message, if it is yourself, the background is light gray, else the background is white
      else if message.type == 'user_message'
        message.textColor = black333
        message.borderColor = borderNone
        currentSender = message.name
        message.nameColor = hyperlinkBlue
        currentTime = message.time

        if lastSender == currentSender
          sameSender = true
          if currentTime - lastTime < 60000
            sameTime = true
        else
            currentColor = white

        message.backgroundColor = currentColor


        if message.message.indexOf('slaps') >= 0
          message.textColor = pink

        lastSender = currentSender
        lastTime = currentTime

    message.sameTimeFlag = sameTime
    message.sameSenderFlag = sameSender
  lastSender = null
  currentColor = white

  #dont update messageLimit if this was called through the periodic update.
  if forcedUpdate
    forcedUpdate = false

  #return the array of all the requested messages
  return allMessages

###
@Function: getActiveUsers
@Description: Grabs active users in room
@params: string that represents the room name
@return: the array of active users
@pre: called in room_active_users template
@post: None
###
Template.room_active_users.getActiveUsers = (roomName) ->
  if roomName != undefined and roomName != null
    Rooms.findOne({room_name: roomName}).active_users

###
@Function: getAvailableRooms
@Description: Sorts rooms based off of room name in lexicographical order
@params: None
@return: a cursor on the rooms collection
@pre: called within the global_rooms_available template
@post: None
###
Template.global_rooms_available.getAvailableRooms = ->
  Rooms.find({}, {sort: {room_name: 1}})



### @Event_Handlers ###

###
@Function: hash of functions for the event handling in the input template
@Description: Takes either a button click or an Enter
      key input and calls the sndMsg function
@pre: None
@post: Event handlers exist on the input template
###
Template.input.events =
  #capture a enter key and send the message
  "keydown textarea#chat-message-input": (event) ->
    message = document.getElementById("chat-message-input")
    if event.which is 13
      if !event.shiftKey # 13 is the enter key event
        sndMsg()
        #prevents newline after message send
        event.preventDefault()
  #capture the button click and send the message
  "click span#chat-send-message-button": ->
    sndMsg()
    event.preventDefault()
  "mouseup #chat-message-input": ->
    @style.height = 0
    @style.height = @scrollHeight + "px"
    return


###
@Function: hash of functions for the event handling in the chat template
@Description: Throws an event when the user scrolls to the top of the chat box
@pre: None
@post: Event handlers exist on the chat template
###
Template.chat.events =
  #throw event when the user gets to the top of chat box.
  "scroll div.chat-messages-container": ->
    document.topCheck = false if document.gettingMoreMessages == false
    if chatDiv.scrollTop == 0 and document.gettingMoreMessages == false
      document.gettingMoreMessages = true
      document.topCheck = true
      document.progressiveRenderCount = 0
      chatBox = chatDiv.children[0]
      scrollTopChild = null
      for message in chatBox.children
        if message.getAttribute("id") == "chat-message-scroll-"
          continue
        else
          scrollTopChild = message
          break
      Session.set('newFirstMessageIndex', firstMessageIndex - 25)
      #Have to set document.bottomCheck to false or else the messages will scroll to the bottom when they review history if the were at the bottom when the last message came in.
      #We can also know that the user is not at the bottom if they are scrolling to the top.
      document.bottomCheck = false
      #forces update on message template

  "click #invite-single-user": ->
    # Add user to invited users Array
    if allowedUsers.indexOf(this._id) == -1
      allowedUsers.push this._id
    getUsersDep.changed()

  "click #remove-single-user": ->
    # Remove user from invited users Array
    indexOfUser = allowedUsers.indexOf(this._id)
    allowedUsers.splice(indexOfUser, 1)
    getUsersDep.changed()

  "click #chat-invite-users-button": ->
    allowedUsers = Rooms.findOne({room_name: data.room_name}).allowed_users
    getUsersDep.changed()

  "click #chat-empty-bookmark": ->
    forcedUpdate = true
    Meteor.call('insertBookmark', this, data._id)

  "click #chat-full-bookmark": ->
    forcedUpdate = true
    Meteor.call('removeBookmark', this)

  "click #chat-modal-close-confirm": (e) ->
    Meteor.call('setAllowedUsers', data.room_name, allowedUsers)

  "click #delete-room": ->
    $("#delete-room").css('display', 'none')
    $(".room-remove-confirm").css('display', 'block')

  "click .room-remove-confirm-yes": ->
    Meteor.call('deleteRoom', data._id)
    Router.go("home")

  "click .room-remove-confirm-no": ->
    $("#delete-room").css('display', 'inline-block')
    $(".room-remove-confirm").css('display', 'none')

  "click .chat-message-contents a": ->
    $("#chat-message-scroll-#{this.index} a").attr("target", "_blank")

###
@Function: createEventHandles
@Description: Makes the focus and blur events on the current window so you can tell if a user has a page focused or not.
@pre: None
@post: Event handlers exist on the current window
###
createEventHandles = () ->
  #capture the focus and blur events
  $(window).on("blur focus", (e) ->
    #remember the last event captured
    prevType = $(this).data("prevType")
    if prevType != e.type
      if e.type == "blur"
        document.active = false
      else if e.type == "focus"
        flashBool = false
        document.title = original
        setFavicon(greenFavicon)
        document.active = true
    $(this).data("prevType", e.type)
  )

###
@Function: destroyEventHandles
@Description: remove the event handles for this window
@pre: Event handles for focus and blur exist on this page
@post: window no longer has focus and blur event handles
###
destroyEventHandles = () ->
  $(window).off("focus blur")



### @Miscellaneous_Functions ###

###
@Function: sndMsg
@Description: Grabs text from the input field and
      calls a function to insert it into the
      database
@params: None
@return: None
@pre: None
@post: message from input box is inserted into the database
###
sndMsg = ->
  message = document.getElementById("chat-message-input")
  if message.value != ""
    if message.value[0] == "/"
      getEmoticon(message.value)
    else
      Meteor.call("insertMsg", message.value, data._id, "user_message")

    message.value = ""

###
@Function: setFavicon
@Description: Set the favicon for the current page. Used in conjunction with flashing title.
@params: A string that is the path for the favicon
@return: None
@pre: None
@post: Favicon on page is set to the param passed
###
setFavicon = (favicon)->
  link = document.createElement("link")
  link.rel = "icon"
  link.href = favicon
  link.sizes = "16x16 32x32"
  document.getElementsByTagName("head")[0].appendChild link
  return

###
@Function: setScrollToBottom
@Description: Set scroll bar of the chat box to the bottom
@params: None
@return: None
@pre: None
@post: Scroll bar of chat div is set to the bottom
###
setScrollToBottom = () ->
  if firstPageLoad
    $(chatDiv).waitForImages ->
      chatDiv.scrollTop = chatDiv.scrollHeight
  else
    firstPageLoad = false
    chatDiv.scrollTop = chatDiv.scrollHeight
  return

###
@Function: convertToLocalTime
@Description: Converts UTC timestamp to readable format to be displayed in the chat
@params: String representing UTC timestamp
@return: A string that represents the time in a readable format
@pre: None
@post: None
###
convertToLocalTime = (UTCtime) ->
  longTimeStamp = (new Date(UTCtime).toString()).split(" ", 5)
  date = longTimeStamp[1] + " " + longTimeStamp[2]
  year = longTimeStamp[3]
  timeElements = longTimeStamp[4].split(":")
  hours = parseInt(timeElements[0], 10)
  minutes = timeElements[1]
  period = "pm"
  if hours < 12
    if hours == 0
      hours = 12
    period = "am"
  else if hours > 12
    hours -= 12
  time = hours + ":" + minutes + " " + period
  if new Date(UTCtime).getFullYear() == new Date().getFullYear() and new Date(UTCtime).getMonth() == new Date().getMonth() and new Date(UTCtime).getDate() == new Date().getDate()
    return time
  else if new Date(UTCtime).getFullYear() == new Date().getFullYear()
    return date + " " + time
  else
    return date + " " + year + " " + time

###
@Function: convertToLocalTime
@Description: Converts UTC timestamp to readable format to be displayed in the chat
@params: String representing UTC timestamp
@return: A string that represents the time in a readable format
@pre: None
@post: None
###
convertToLocalTime = (UTCtime) ->
  longTimeStamp = (new Date(UTCtime).toString()).split(" ", 5)
  date = longTimeStamp[1] + " " + longTimeStamp[2]
  year = longTimeStamp[3]
  timeElements = longTimeStamp[4].split(":")
  hours = parseInt(timeElements[0], 10)
  minutes = timeElements[1]
  period = "pm"
  if hours < 12
    if hours == 0
      hours = 12
    period = "am"
  else if hours > 12
    hours -= 12
  time = hours + ":" + minutes + " " + period
  if new Date(UTCtime).getFullYear() == new Date().getFullYear() and new Date(UTCtime).getMonth() == new Date().getMonth() and new Date(UTCtime).getDate() == new Date().getDate()
    return time
  else if new Date(UTCtime).getFullYear() == new Date().getFullYear()
    return date + " " + time
  else
    return date + " " + year + " " + time

###
@Function: getEmoticon
@Description: <placeholder>
@params: <placeholder>
@return: <placeholder>
@pre: <placeholder>
@post: <placeholder>
###
getEmoticon = (message) ->
  originalMessage = message
  if message.substring(0, 5) == "/slap"
    originalMessage = message.substring(6)
    target = originalMessage.substring(0)
    if target == ""
      target = "the room"
    if Meteor.user().profile.name != "" and Meteor.user().profile.name != null and Meteor.user().profile.name != undefined
      name = Meteor.user().profile.name
    else
      name = Meteor.user().profile.login

    # Array of random items to slap people with
    slapItems = ["large trout", "speckled salmon", "rubber chicken", "two by four", "bag of doritos", "blow up globe",
      "grayish blob", "tuba", "pikachu", "balloon animal", "helium canister", "pet goldfish", "wacky wavy inflatable arm-flailing tube-man"]

    # Picks a random item to slap people with
    randomItem = slapItems[Math.floor(Math.random() * slapItems.length)]

    Meteor.call("insertMsg", (name + " slaps " + target + " with a " + randomItem) , data._id, "user_message")
  else if message.substring(0, 7) == "/shrekt"
    Meteor.call("insertMsg", ("![Shrekt](/shrek.jpg)") , data._id, "user_message")
  # Uncomment to allow for messages to start with "/"
  else
    Meteor.call("insertMsg", message, data._id, "user_message")


###
@Function: getNthWord
@Description: gets the Nth word from a string
@params: string to find the word in, index n
@return: nth word
@pre: None
@post: None
###
# gets the nth word of a sentence
getNthWord = (string, n) ->
  words = string.split(" ");
  return words[n-1];

###
@Function: splitString
@Description: <placeholder>
@params: <placeholder>
@return: <placeholder>
@pre: <placeholder>
@post: <placeholder>
###
# splits string by each character to give this ["h", "e", "l", "l", "o"]
splitString = (string) ->
  splitArray = string.split("")

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
      if allowedUsers.indexOf(user._id) == -1
        Meteor.call('addAllowedUser', room_Name, user._id)
  else
    room.invitedUsers = []





### @UI_Helpers ###

###
@Function: showInviteUsers
@Description: ensures that the invite users button only exists if the user is the owner
        and the room is private
@params: none
@return: true or false
@pre: Can only be called in handlebars.
@post:
###
UI.registerHelper 'isChatPrivate', () ->
  !data.public

###
@Function: isAllowed
@Description: returns whether or not a user is in the invitedUsers Array
@params: user object
@return: true or false
@pre: Can only be called in handlebars.
@post:
###
UI.registerHelper "isAllowed", (user) ->
  if !data.public # Check if userID is in invitedUsers Array
    if user._id in allowedUsers
      return false
    else
      return true

###
@Function: convertMsg
@Description: converts any given msg into markdown
@params: message (string)
@return: string
@pre: Can only be called in handlebars.
@post:
###
UI.registerHelper 'convertMsg', (message) ->
  # This will be potentially used to sanatize out any/all raw html input
  marked.setOptions
    sanitize: true

  if message != undefined
    marked(message)

###
@Function: moreThan25Messages
@Description: checks if there are more than 25 messages, if so, adds "..." to the top of the list to scroll up
@params: number of messages
@return: boolean
@pre: Can only be called in handlebars.
@post:
###
UI.registerHelper 'moreThan25Messages', (numberOfMessages) ->
  # if oldMessageCount >= 25
  #   return true
  # else
  #   return false


###
@Function: getPic
@Description: Gets and returns the url for a user's GitHub avatar
@params: user object
@return: string representing the url of the user's avatar
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper "getPic", (user) ->
  user.profile.avatar_url

###
@Function: getLoginName
@Description: Gets and returns the GitHub username of the user
@params: user object
@return: string representing the user's GitHub handle
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper "getLoginName", (user) ->
  user.profile.login

###
@Function: convertToLocalTime
@Description: Calls convertToLocalTime function.
@params: Integer
@return: String representing timestamp in a readable format
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper "convertToLocalTime", (UTCtime) ->
  if UTCtime != undefined
    convertToLocalTime(UTCtime)



###
@Function: notSystemMsg
@Description: Returns true if the message is not a system message
@params: message object
@return: boolean
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper 'notSystemMsg', (type) ->
  if type == 'system_message'
    return false
  else
    return true


###
@Function: bmCountIsNotZero
@Description: Returns true if the bookmark count is not 0
@params: message object
@return: boolean
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper 'bmCountIsNotZero', (count) ->
  if count == 0 or count == undefined
    return false
  else
    return true

###
@Function: isBookmarked
@Description: Determines whether a given message is bookmarked by the user
@params: message object
@return: bool: true if bookmarked, false if not
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper 'isBookmarked', (messageId) ->
  if Bookmarks.findOne({messages: {$elemMatch: {_id: messageId}}}) != undefined
      return true
    else
      return false

###
@Function: isRoomOwner
@Description: checks to see if the user is the owner of the room
@params:
@return:
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper 'isRoomOwner', () ->
  currentUser = Meteor.user()
  return Meteor.user()._id == data.owner._id


###
@Function: sameSender
@Description:
@params:
@return:
@pre: Can only be called in handlebars.
@post: None
###
UI.registerHelper 'sameSender', () ->
  return sameSender


### @Dependencies ###


Deps.autorun () ->
  firstMessage = Messages.findOne({type: 'user_message'}, {sort: {index: 1}})
  if firstMessage
    firstMessageIndex = firstMessage.index

Deps.autorun () ->
  sub = Meteor.subscribe('user_messages', Session.get('currentRoomId'), Session.get('newFirstMessageIndex'))



####################3 Autocomplete Attempts #####################3

Template.autocomplete.settings = () ->
  return {
    position: "top",
    limit: 10,
    rules: [
      token: '@',
      collection: Meteor.users,
      field: "profile.login",
      template: Template.autoCompleteUsers
      noMatchTemplate: Template.autoCompleteNotFound
      selector: (match) ->
          regex = new RegExp(match, 'i')
          return {$or: [{'profile.display_name': regex}, {'profile.login': regex}]}
    ]
  }
