#! /bin/bash
OPTIND=1  


if test  "$#" -lt 1; then
    echo "xpl-tts-say.sh [message] -v [voice] -l [level]"
    echo " voice  : google, "
    echo "          loic, papi, electra, robot, sorciere,ramboo,  yeti, philippe darkvador john helene zozo"
    echo "            enfant : emma, matteo (enfant) "
    echo "            fun   : bicool , chut, melodine(chante), darkvador"
    echo "            homme : damien (x) ludovic loic (x) jeanjean (quebec) john (americain)"
    echo "            femme : electra (sensuelle) agnes (claire) fabienne eva"
    echo " level : 0 to 100"
    echo " " 
    echo " samples:"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  -v google"
    echo "    xpl-tts-say.sh \"bonjour, test de message\"  -v yeti"
    exit -1
fi

# default
MESSAGE=""
VOICE="loic"
LEVEL="100"

while [[ $# > 1 ]]
do
key="$1"

case $key in    

    -v|--voice)
    VOICE="$2"
    shift 
    ;;
    -l|--level)
    LEVEL="$2"
    shift
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
	MESSAGE="$MESSAGE $key"
            # unknown option
    ;;
esac
shift
done

MESSAGE="$MESSAGE $@"

echo "----------------------" >> /tmp/xplTTS.log
echo "MESSAGE : $MESSAGE" >> /tmp/xplTTS.log
echo "VOICE   : $VOICE"   >> /tmp/xplTTS.log
echo "LEVEL   : $LEVEL"   >> /tmp/xplTTS.log

xpl-sender -m xpl-cmnd -c tts.basic voice="$VOICE" speech="$MESSAGE" volume="$LEVEL"
