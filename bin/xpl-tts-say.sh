#! /bin/bash

DEFVOICE="google"

if test  "$#" -lt 1; then
    echo "xpl-tts-say.sh [message] [voice]"
    echo "voice: google, agnes, loic, papi, electra, robot, sorciere, melodine, ramboo, chut, yeti, bicool"
    echo " " 
    echo " samples:"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  google"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  yeti"
    exit -1
fi

MESSAGE=$1
VOICE=${2:$DEFVOICE}

echo "MESSAGE : $MESSAGE"
echo "VOICE   : $VOICE"

xpl-sender -m xpl-cmnd -c tts.basic voice="$VOICE" speech="$MESSAGE" 
