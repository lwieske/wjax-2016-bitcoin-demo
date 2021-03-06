#!/usr/bin/env bash

################################################################################
### prepare demo ###############################################################
################################################################################

docker stop $(docker ps -a -q) ; docker rm $(docker ps -a -q)

################################################################################
### record #####################################################################
################################################################################

asciinema rec -y \
  -c "bash -x run_txs.sh" \
  demo.json

################################################################################
### postprocess ################################################################
################################################################################

ASCIICAST=`asciinema upload demo.json`

APICAST=https://asciinema.org/api/asciicasts/${ASCIICAST:24}

asciinema2gif --size small --theme asciinema -o demo.gif ${APICAST}

gifsicle --colors 4 --resize 800x600 --use-colormap gray demo.gif >demo800x600.gif

rm demo.gif demo.json
