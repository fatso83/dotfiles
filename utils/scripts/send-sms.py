#!/usr/bin/env python3
import requests
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument(
        "--phone", type=str, required=True, action="append", 
        help="Can be repeated. If the number is only 8 digits, assumes 47 (Norway country code) should be prepended.")
parser.add_argument("--file", type=open)
parser.add_argument("--msg", type=str)
parser.add_argument("--id", type=str)
parser.add_argument("--secret", type=str)
parser.add_argument("--from", type=str, dest="from_nmbr")
parser.add_argument("--unicode", action="store_const", const=True, help="Use unicode to encode the message")
parser.add_argument("--stats", action="store_const", const=True, help="Show last sent messages")
parser.add_argument("--debug", action="store_const", const=True, help="Prints the raw return")
parsed = parser.parse_args()

if parsed.msg and parsed.file:
    print("Cannot specify both a msg and a file to read from!")
    exit(1)

msg = parsed.msg or parsed.file.read()
if not msg:
    print("No message given. See params --msg and --file")
    exit(1)

try:
    sms_id = parsed.id or os.environ['BULKSMS_ID']
    sms_secret = parsed.secret or os.environ['BULKSMS_SECRET']
except Exception as e:
    # TODO: try reading them from ~/.bulksms.auth
    print("Could not find credentials to authenticate")
    print("Need environment variables BULKSMS_ID and BULKSMS_SECRET set" )
    exit(1)

numbers = ["+47" + p if len(p) is 8 else p for p in parsed.phone]
from_nmbr = parsed.from_nmbr or "+4740065078"

encoding = "TEXT" if not parsed.unicode else "UNICODE"
url = "https://api.bulksms.com/v1/messages"

# See http://developer.bulksms.com/json/v1/
payload = {
    "to":   numbers,
    "from": from_nmbr,
    "encoding": encoding,
    "body": msg
}

if parsed.stats:
    r = requests.get(url, json=payload, auth=(sms_id, sms_secret), timeout=1)
    # if r.status_code is 200:
    print(r.text)
else:
    r = requests.post(url, json=payload, auth=(sms_id, sms_secret), timeout=1)
    if r.status_code is not 201 or parsed.debug:
        print(r.text)

