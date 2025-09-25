#!/usr/bin/env python3
import requests
import os
import argparse
import smsutil

url = "https://api.bulksms.com/v1/messages"
profile_url = "https://api.bulksms.com/v1/profile"


parser = argparse.ArgumentParser()
parser.add_argument(
        "--phone", type=str, action="append", 
        help="Can be repeated. If the number is only 8 digits, assumes 47 (Norway country code) should be prepended.")
parser.add_argument("--phone-file", type=open, help="One number per line")
parser.add_argument("--file", type=open)
parser.add_argument("--msg", type=str)
parser.add_argument("--id", type=str)
parser.add_argument("--secret", type=str)
parser.add_argument("--from", type=str, dest="from_nmbr")
parser.add_argument("--unicode", action="store_const", const=True, help="Use unicode to encode the message")
parser.add_argument("--force-text", action="store_const", const=True, help="Force normal GSM 03.38 encoding. Unsupported characters are replaced with '?'")
parser.add_argument("--history", action="store_const", const=True, help="Show last sent messages")
parser.add_argument("--profile", action="store_const", const=True, help="Show profile - including credits")
parser.add_argument("--debug", action="store_const", const=True, help="Prints the raw return")
parser.add_argument("--max-parts", type=int, default=6, help="In case the message is too long to fit, increase this. Each part is 153 characters - 67 if unicode")
parsed = parser.parse_args()

try:
    sms_id = parsed.id or os.environ['BULKSMS_ID']
    sms_secret = parsed.secret or os.environ['BULKSMS_SECRET']
except Exception as e:
    # TODO: try reading them from ~/.bulksms.auth
    print("Could not find credentials to authenticate")
    print("Need environment variables BULKSMS_ID and BULKSMS_SECRET set" )
    exit(1)

if parsed.profile:
    r = requests.get(profile_url, auth=(sms_id, sms_secret), timeout=1)
    print(r.text)
    exit(0)

if parsed.history:
    r = requests.get(url, auth=(sms_id, sms_secret), timeout=1)
    print(r.text)
    exit(0)

if not parsed.phone and not parsed.phone_file:
    print("You need to specify --phone or --phone-file")
    parser.print_help()
    exit(1)

if parsed.phone_file and parsed.phone:
    print("Can only handle phone numbers from file OR from the command line, not both")
    exit(1)

numbers = []
if parsed.phone:
    numbers = ["+47" + p if len(p) == 8 else p for p in parsed.phone]

if parsed.phone_file:
    numbers = ["+47" + p if len(p) == 8 else p for p in parsed.phone_file.read().splitlines()]

if parsed.msg and parsed.file:
    print("Cannot specify both a msg and a file to read from!")
    exit(1)

msg = parsed.msg or (parsed.file and parsed.file.read())
if not msg:
    print("No message given. See params --msg and --file")
    exit(1)

if not smsutil.is_valid_gsm(msg) and not parsed.unicode and not parsed.force_text:
    print("This message contains characters not in the normal set of SMS characters. Use the `--unicode` or `--force-text` flag.")
    exit(1)


from_nmbr = parsed.from_nmbr or "+4740065078"

encoding = "TEXT" if not parsed.unicode else "UNICODE"

# See http://developer.bulksms.com/json/v1/
payload = {
    "to":   numbers,
    "from": from_nmbr,
    "encoding": encoding,
    "body": msg,
    "longMessageMaxParts": parsed.max_parts
}

# timeout in seconds
r = requests.post(url, json=payload, auth=(sms_id, sms_secret), timeout=5)
if r.status_code != 201 or parsed.debug: 
    print(r.text)
