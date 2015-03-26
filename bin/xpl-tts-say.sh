#! /bin/bash

DEFVOICE="google"
DEFVOLUME="80"

if test  "$#" -lt 1; then
    echo "xpl-tts-say.sh [message] [voice] [volume]"
    echo "voice  : google, agnes, loic, papi, electra, robot, sorciere, melodine, ramboo, chut, yeti, bicool"
    echo "volume : 0 to 100"
    echo " " 
    echo " samples:"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  google"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  yeti"
    exit -1
fi

MESSAGE=$1
VOICE=${2:$DEFVOICE}
VOLUME=$3

echo "MESSAGE : $MESSAGE"
echo "VOICE   : $VOICE"
echo "VOLUME  : $VOLUME"

xpl-sender -m xpl-cmnd -c tts.basic voice="$VOICE" speech="$MESSAGE" volume="$VOLUME"
