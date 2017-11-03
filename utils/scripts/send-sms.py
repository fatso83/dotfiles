import urllib

# Please see the FAQ regarding HTTPS (port 443) and HTTP (port 80/5567)

url = "https://bulksms.vsms.net/eapi/submission/send_sms/2/2.0"
params = urllib.urlencode({'username' : 'myusername', 'password' : 'xxxxxxxx', 'message' : 'Testing Python', 'msisdn' : 271231231234})
f = urllib.urlopen(url, params)

s = f.read()

result = s.split('|')
statusCode = result[0]
statusString = result[1]
if statusCode != '0':
    print "Error: " + statusCode + ": " + statusString
else:
    print "Message sent: batch ID " + result[2]

f.close()
