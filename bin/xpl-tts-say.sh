#! /bin/bash
echo "TTS : $1"
xpl-sender -m xpl-cmnd -c tts.basic speech="$1"
