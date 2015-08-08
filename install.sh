#! /bin/bash

INSTALL_PATH=/usr/local/bin/

TTS_SERVER=bin/xpl-tts.pl
TTS_CLIENT=bin/xpl-tts-say.sh
INIT_SCRIPT=init.d/xpl-tts

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function install_server {

	echo "Install server mode: "
        cp $TTS_SERVER $INSTALL_PATH

        echo "Install init.d script: "
        cp $INIT_SCRIPT /etc/init.d/
        update-rc.d xpl-tts defaults
}

function install_client {
	echo "Install client mode: "
	cp $TTS_CLIENT $INSTALL_PATH
}

case "$1" in
  server)
	install_server
	install_client
  	;;
  client)
	install_client
	;;
  *)
	echo "$0 [server|client]"
	echo " server: install daemon and client files"
        echo " client: client tool only"
	;;
esac
