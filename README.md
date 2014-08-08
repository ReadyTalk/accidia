#Accidia
###DISCLAIMER:
This product is in NO WAY associated with other ReadyTalk products and will not be supported as such. This project was a summer intern project that is now lightly moderated by the interns who created it.

###Description:
Accidia is meant to an internal collaboration tool for developers built with Meteor. It is much like other chat applications out there but with a few distinctive features that cater towards developers, the main one being that the chat supports input of MarkDown.

###Product Vision:
The project idea was originally concieved by the engineering management team at ReadyTalk. Jesse Weave and Dan Cunningham were the two that lead the development as the project progressed over the summer. One of the major motivatiosn for this project was that many of the other tool like this out there have all sorts of various issues that we inheriently tried to avoid while developing.

###Completed Feature List:
 - Group chat
 - Private chat
 - Mentioning system
 - Markdown input
 - Ability to invite users to room
 - Bookmarking / Favoriting system
 - Active users list
 - Online users list

###Upcoming/Desired Changes:
 - FAQ Page
 - Google Authentication
 - Email system
 - File Upload / Storage
 - Message editing / deletion
 - Message tagging / flagging
 - Chat controls for easier input for markdown
 - Testing framework (When Velocity becomes more stable)
 - More secure storage of messages
 - Github / Other version control integration
 - Jira / Other project management integration


###How to Contribute:
 - Fix bugs in the issues list
 - Work on the addition of new features outlined above
 - ~~Write tests~~ (Waiting on Velocity to become more stable)

###Requirements:
Meteor: 0.8.3

###Setup:
In order to get the app to run properly you must setup a GitHub application. So, setup a new GitHub application with the proper URLs. I recommend that you export your local ip instead of using `http://localhost:3000` as their are issues with using localhost with GitHub authorization.

Then you must add a `config.coffee` file with the following code:

```
ServiceConfiguration.configurations.remove service: "github"
ServiceConfiguration.configurations.insert
	service: 'github'
	clientId: "Your ClientID"
	secret: "Your Secret"
```

This should be enough to run the application. Then just start the server using `mrt`

####License:
MIT



