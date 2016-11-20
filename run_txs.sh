#!/usr/bin/env bash

VERSION=0.13.1

docker run -d --name bitcoind                                                  \
  lwieske/bitcoincore:d-${VERSION}                                             \
            -regtest=1                                                         \
            -printtoconsole                                                    \
            -rpcallowip=172.17.0.0/16                                          \
            -rpcuser=foo                                                       \
            -rpcpassword=bar

docker inspect -f '{{.Name}} - {{.NetworkSettings.IPAddress }}' $(docker ps -aq)

sleep 10

################################################################################
################################################################################
################################################################################

CALL="docker run --rm -it lwieske/bitcoincore:cli-${VERSION}"
ARGS="-regtest -rpcuser=foo -rpcpassword=bar -rpcconnect=172.17.0.2"

BITCOINCLI="${CALL} ${ARGS}"

################################################################################
################################################################################
################################################################################

### coinbase transactions can be spent after 100 other blocks

${BITCOINCLI} generate 1

${BITCOINCLI} getbalance

${BITCOINCLI} generate 100

${BITCOINCLI} getbalance

### simple 10 BTCs sendtoaddress; after mining they can be spent

ADDRESS1=$(${BITCOINCLI} getnewaddress)

${BITCOINCLI} sendtoaddress ${ADDRESS1} 10

${BITCOINCLI} listunspent 0

${BITCOINCLI} generate 1

${BITCOINCLI} listunspent 0

################################################################################
### P2PKH ######################################################################
################################################################################

### 1-in/1-out 49.90 BTCs rawtransaction (sign/seal/deliver) / P2PKH ###########

RESULT=`${BITCOINCLI} getnewaddress`
PKHADDRESS=${RESULT%?}

UTXOS=$(${BITCOINCLI} listunspent)

COINBASEUTXO=$(echo ${UTXOS} | jq '.[] | select(.amount == 50.00000000)')

TXINS=$(echo ${COINBASEUTXO} | jq '[{"txid":.txid,"vout":.vout}]')
TXOUTS="{\"${PKHADDRESS}\":49.90}"

RESULT=$(${BITCOINCLI} createrawtransaction "${TXINS}" ${TXOUTS})
UNSIGNEDRAWTX=${RESULT%?}

${BITCOINCLI} decoderawtransaction ${UNSIGNEDRAWTX}

RESULT=$(${BITCOINCLI} signrawtransaction ${UNSIGNEDRAWTX})
SIGNEDRAWTX=$(echo ${RESULT} | jq --raw-output '.hex')

${BITCOINCLI} sendrawtransaction ${SIGNEDRAWTX}

${BITCOINCLI} generate 1

${BITCOINCLI} listunspent 0

### 3-in/2-out 74.95 BTCs rawtransaction (sign/seal/deliver) / P2PKH ###########

${BITCOINCLI} generate 2

RESULT=`${BITCOINCLI} getnewaddress`
PKHADDRESS1=${RESULT%?}

RESULT=`${BITCOINCLI} getnewaddress`
PKHADDRESS2=${RESULT%?}

UTXOS=$(${BITCOINCLI} listunspent)

TXINS=$(echo ${UTXOS} | jq '[.[] | select(.amount == 50.00000000) | {"txid":.txid,"vout":.vout}]')
TXOUTS="{\"${PKHADDRESS1}\":74.95,\"${PKHADDRESS2}\":74.95}"

RESULT=$(${BITCOINCLI} createrawtransaction "${TXINS}" ${TXOUTS})
UNSIGNEDRAWTX=${RESULT%?}

${BITCOINCLI} decoderawtransaction ${UNSIGNEDRAWTX}

RESULT=$(${BITCOINCLI} signrawtransaction ${UNSIGNEDRAWTX})
SIGNEDRAWTX=$(echo ${RESULT} | jq --raw-output '.hex')

${BITCOINCLI} sendrawtransaction ${SIGNEDRAWTX}

${BITCOINCLI} generate 1

${BITCOINCLI} listunspent 0
