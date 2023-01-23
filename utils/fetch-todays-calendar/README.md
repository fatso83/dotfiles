# Fetch todays calender

> Does exactly what is says

Fetches the Google Calendar of today and outputs it in JSON to stdout. Supposed to be used in a cron
job that is used togetether with a Luxafor script that starts and stops the Luxafor light for calendar events.

# To install

Get hold of the credentials.json file. If you do not already have this OAuth id and secret, create one in your 
Project in the Google Developer Console:   

> Project "Your Project" -> Api & Services -> Credentials -> Calendar Fetch  CLI App (create this if it does not exist)

Refer to the Getting Started docs for Node on Google Calendar for more info.

```
$ npm install -g

$ cp 'credentials.json ~/.config/@fatso83/fetch-todays-calendar/'

$ fetch-todays-calendar 
No upcoming events found.

$ fetch-todays-calendar --json
[]
```

