#!/usr/bin/env node
/*
 * Largely based on the base example app from the official Getting Started docs
 *
 * Also:
 * https://developers.google.com/calendar/api/v3/reference
 * https://googleapis.dev/nodejs/googleapis/latest/calendar/classes/Calendar.html
 **/
const os = require("os");
const fs = require("node:fs/promises");
const fsSync = require("fs");
const path = require("path");
const process = require("process");
const { authenticate } = require("@google-cloud/local-auth");
const { google } = require("googleapis");

// If modifying these scopes, delete token.json.
const SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"];
// The file token.json stores the user's access and refresh tokens, and is
// created automatically when the authorization flow completes for the first
// time.
const APP_CONFIG_DIR = path.join(
  os.homedir(),
  ".config/@fatso83/fetch-todays-calendar"
);
const TOKEN_PATH = path.join(APP_CONFIG_DIR, "token.json");
const CREDENTIALS_PATH = path.join(APP_CONFIG_DIR, "credentials.json");

if (!fsSync.statSync(APP_CONFIG_DIR, { throwIfNoEntry: false })) {
  fsSync.mkdirSync(APP_CONFIG_DIR, { recursive: true });
}

if (!fsSync.statSync(CREDENTIALS_PATH, { throwIfNoEntry: false })) {
  console.warn(
    `The credentials.json file is missing from the config directory. 

     This is a set of OAuth id and secret to identify the app to Google (and thus enforce billing, quoatas, etc).
     For the Diffia AS company, you will find this in Project "Calender Fetch" -> Api & Services -> Credentials -> Calendar Fetch  CLI App 

     Just press the "Download" link and save the file in the app directory (${CREDENTIALS_PATH})`
  );

  if (!fsSync.statSync(TOKEN_PATH, { throwIfNoEntry: false })) {
    process.exit(1);
  } else {
    console.log(
      "While the credentials are missing, somehow the token file has been created, so we can continue and ignore the error."
    );
  }
}

/**
 * Reads previously authorized credentials from the save file.
 *
 * @return {Promise<OAuth2Client|null>}
 */
async function loadSavedCredentialsIfExist() {
  try {
    const content = await fs.readFile(TOKEN_PATH);
    const credentials = JSON.parse(content);
    return google.auth.fromJSON(credentials);
  } catch (err) {
    return null;
  }
}

/**
 * Serializes credentials to a file compatible with GoogleAUth.fromJSON.
 *
 * @param {OAuth2Client} client
 * @return {Promise<void>}
 */
async function saveCredentials(client) {
  const content = await fs.readFile(CREDENTIALS_PATH);
  const keys = JSON.parse(content);
  const key = keys.installed || keys.web;
  const payload = JSON.stringify({
    type: "authorized_user",
    client_id: key.client_id,
    client_secret: key.client_secret,
    refresh_token: client.credentials.refresh_token,
  });
  await fs.writeFile(TOKEN_PATH, payload);
}

/**
 * Load or request or authorization to call APIs.
 *
 */
async function authorize() {
  let client = await loadSavedCredentialsIfExist();
  if (client) {
    return client;
  }
  client = await authenticate({
    scopes: SCOPES,
    keyfilePath: CREDENTIALS_PATH,
  });
  if (client.credentials) {
    await saveCredentials(client);
  }
  return client;
}

/**
 * Lists the next 10 events on the user's primary calendar.
 * @param {google.auth.OAuth2} auth An authorized OAuth2 client.
 */
async function listEvents(auth) {
  const now = new Date();
  const inHalfADay = new Date(now + 3 * 3600 * 1000);

  const calendar = google.calendar({ version: "v3", auth });
  const res = await calendar.events.list({
    calendarId: "primary",
    timeMin: now.toISOString(),
    timeMax: inHalfADay.toISOString(),
    maxResults: 10,
    singleEvents: true,
    orderBy: "startTime",
  });
  return res.data.items;
}

authorize()
  .then(listEvents)
  .then((events) => {
    if (process.argv[2] === "--json") {
      console.log(events);
    } else {
      if (!events || events.length === 0) {
        console.log("No upcoming events found.");
        return;
      }
      console.log("Upcoming 10 events:");
      events.map((event, i) => {
        const start = event.start.dateTime || event.start.date;
        console.log(`${start} - ${event.summary}`);
      });
    }
  })
  .catch(console.error);
