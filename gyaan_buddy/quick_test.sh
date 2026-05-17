#!/bin/bash

# Quick Firebase Notification Test
# Usage: ./quick_test.sh YOUR_SERVER_KEY

FCM_TOKEN="f7akI1vE8Em4uK_ZrsKeNp:APA91bHJTZDa0tsb_mA1zVSME1ppnoOfnHWL1ZbAYYr0vVsjQ83IJpoxmeU8xJL4-naGAK08y-bIxHTEsqtm1j6RaKoOUZSKVovT-AGa3-7IhKHsXWDVvyA"

if [ -z "$1" ]; then
    echo "❌ Usage: ./quick_test.sh YOUR_SERVER_KEY"
    echo "📱 Get your Server Key from Firebase Console → Project Settings → Cloud Messaging"
    exit 1
fi

echo "🚀 Sending test notification..."

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=$1" \
  -H "Content-Type: application/json" \
  -d "{
    \"to\": \"$FCM_TOKEN\",
    \"notification\": {
      \"title\": \"Test Notification\",
      \"body\": \"This is a test notification from server\"
    },
    \"data\": {
      \"screen\": \"home\",
      \"action\": \"navigate\",
      \"type\": \"general\"
    }
  }"

echo ""
echo "✅ Test notification sent! Check your app."
