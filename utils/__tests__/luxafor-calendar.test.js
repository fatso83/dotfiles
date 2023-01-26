const {
  fileExists,
  isAttenderOfEvent,
  isPartOfMeeting,
  isTentativeAttenderOfEvent,
} = require("../scripts/luxafor-calendar");
const assert = require("assert");

function difference(setA, setB) {
  const _difference = new Set(setA);
  for (const elem of setB) {
    _difference.delete(elem);
  }
  return _difference;
}

const attendedEvent = {
  id: "id-attended",
  summary: "Attended by me",
  status: "confirmed",
  creator: {
    email: "henrik@some-company.org",
  },
  organizer: {
    email: "henrik@some-company.org",
  },
  start: {
    dateTime: "2023-01-23T12:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  end: {
    dateTime: "2023-01-23T13:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  attendees: [
    {
      email: "carlerik@some-company.org",
      self: true,
      responseStatus: "accepted",
    },
  ],
  eventType: "default",
};
const declinedEvent = {
  id: "id-declined",
  summary: "Attended by me",
  status: "confirmed",
  creator: {
    email: "henrik@some-company.org",
  },
  organizer: {
    email: "henrik@some-company.org",
  },
  start: {
    dateTime: "2023-01-23T12:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  end: {
    dateTime: "2023-01-23T13:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  attendees: [
    {
      email: "carlerik@some-company.org",
      self: true,
      responseStatus: "declined",
    },
  ],
  eventType: "default",
};
const tentativeEvent = {
  id: "id-tentative",
  summary: "Tentatively attended by me",
  status: "confirmed",
  creator: {
    email: "henrik@some-company.org",
  },
  organizer: {
    email: "henrik@some-company.org",
  },
  start: {
    dateTime: "2023-01-23T12:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  end: {
    dateTime: "2023-01-23T13:00:00+01:00",
    timeZone: "Europe/Berlin",
  },
  attendees: [
    {
      email: "carlerik@some-company.org",
      self: true,
      responseStatus: "tentative",
    },
  ],
  eventType: "default",
};
const createdEvent = {
  kind: "calendar#event",
  id: "1r7n87ss39eqhq7rjfcc3lsur5",
  status: "confirmed",
  summary: "Created by me",
  creator: {
    email: "carlerik@some-company.org",
    self: true,
  },
  organizer: {
    email: "someone@some-company.org",
  },
  start: {
    dateTime: "2023-01-23T16:00:00+01:00",
    timeZone: "Europe/Oslo",
  },
  end: {
    dateTime: "2023-01-23T16:50:00+01:00",
    timeZone: "Europe/Oslo",
  },
  iCalUID: "1r7n87ss39eqhq7rjfcc3lsur5@google.com",
  sequence: 0,
  reminders: {
    useDefault: true,
  },
  eventType: "default",
};
const organizedEvent = {
  kind: "calendar#event",
  etag: '"3348970545228000"',
  id: "78kqfpu31o9b1umvhh5nsregfa",
  status: "confirmed",
  summary: "Organized by me",
  creator: {
    email: "someone@some-company.org",
  },
  organizer: {
    email: "carlerik@some-company.org",
    self: true,
  },
  start: {
    dateTime: "2023-01-23T18:00:00+01:00",
    timeZone: "Europe/Oslo",
  },
  end: {
    dateTime: "2023-01-23T18:50:00+01:00",
    timeZone: "Europe/Oslo",
  },
  iCalUID: "78kqfpu31o9b1umvhh5nsregfa@google.com",
  sequence: 0,
  reminders: {
    useDefault: true,
  },
  eventType: "default",
};
const somethingElseEvent = {
  kind: "calendar#event",
  etag: '"3348970557746000"',
  id: "1dcvgt9tholk5tt345h7pj1nt2",
  status: "confirmed",
  htmlLink:
    "https://www.google.com/calendar/event?eid=MWRjdmd0OXRob2xrNXR0MzQ1aDdwajFudDIgY2FybGVyaWtAZGlmZmlhLmNvbQ",
  created: "2023-01-23T14:47:58.000Z",
  updated: "2023-01-23T14:47:58.873Z",
  summary: "should not be included",
  creator: {
    email: "somone@some-company.org",
  },
  organizer: {
    email: "foobar@some-company.org",
  },
  start: {
    dateTime: "2023-01-23T23:30:00+01:00",
    timeZone: "Europe/Oslo",
  },
  end: {
    dateTime: "2023-01-24T00:20:00+01:00",
    timeZone: "Europe/Oslo",
  },
  iCalUID: "1dcvgt9tholk5tt345h7pj1nt2@google.com",
  sequence: 0,
  reminders: {
    useDefault: true,
  },
  eventType: "default",
};

const events = [
  attendedEvent,
  createdEvent,
  organizedEvent,
  somethingElseEvent,
  declinedEvent,
  tentativeEvent,
];

describe("fileExists", function () {
  it("should work", async function () {
    assert(await fileExists(__filename));
  });
  it("should not fail on missing dir or file", async function () {
    assert.equal(false, await fileExists("not-a-dir/this-is-not-a-file"));
  });
});

describe("isAttenderOfEvent", function () {
  it("should return true when one of attenders and response status is 'accepted'", function () {
    assert(isAttenderOfEvent(attendedEvent));
  });
  it("should return false when attenders is missing", function () {
    assert.equal(false, isAttenderOfEvent(createdEvent));
  });
  it("should return false when the response status is something else", function () {
    assert.equal(false, isAttenderOfEvent(tentativeEvent));
    assert.equal(false, isAttenderOfEvent(declinedEvent));
  });
});

describe("isTentativeAttenderOfEvent", function () {
  it("should return true when one of attenders and respone is 'tentative'", function () {
    assert(isTentativeAttenderOfEvent(tentativeEvent));
  });
  it("should return false when attenders is missing", function () {
    assert.equal(false, isTentativeAttenderOfEvent(createdEvent));
  });
  it("should return false when the response status is something else", function () {
    assert.equal(false, isTentativeAttenderOfEvent(attendedEvent));
    assert.equal(false, isTentativeAttenderOfEvent(declinedEvent));
  });
});

describe("isPartOfMeeting", function () {
  it("should only include events organized or attended by myself", function () {
    const results = events.filter(isPartOfMeeting);
    const idsInResultingEvents = results.map((e) => e.id);
    const expectedIds = [
      attendedEvent.id,
      organizedEvent.id,
      tentativeEvent.id,
    ];

    assert.equal(
      0,
      difference(new Set(expectedIds), new Set(idsInResultingEvents)).size
    );
  });
});
