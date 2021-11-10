#!/bin/sh

# This script controls an RPKI-RTR protocol session to an RP specified
# by arguments.  The heavy lifting is done by rtr_client from a customized
# version of Cloudflare's rpki-rtr-client tool kit:
#
#   <https://github.com/jtkristoff/rpki-rtr-client>

# uncomment for debugging
#set -x

# defaults
RTR_CLIENT=/usr/local/bin/rtr_client

# non-critical error
warning() {
    echo ${1:-"Unknown error, continuing..."} >&2
}
# critical failure
fatal() {
    echo ${1:-"Unknown failure, exiting..."} >&2
    exit 1
}

usage() {
    echo "$0 [ -d base_directory ] [ -p port ] [ -t tagname ] rpki-rtr_server"
    echo "  -d base_directory  base data directory  (optional, default: ${HOME}/rpki-rtr/[rpki-rtr_server])"
    echo "  -p port            rpki-rtr port        (optional, default: 323)"
    echo "  -t tagname         RP tagname           (optional, deault: rpki-rtr_server)"
    echo
    echo "  rpki-rtr_server   (required)"
    exit 1
}

# parse command line options
while getopts d:p:t: options
do
    case ${options} in
        d)    DATADIR=${OPTARG}
              ;;
        p)    PORT=${OPTARG}
              ;;
        t)    TAGNAME=${OPTARG}
              ;;
        *)    usage
              ;;
    esac
done
shift `expr ${OPTIND} - 1`

RPKI_RTR_SERVER=$1
# required arguments and options
if [ -z "${RPKI_RTR_SERVER}" ]
then
    usage
fi

if [ -z "${PORT}" ]
then
    PORT=323
fi

if [ -z "${TAGNAME}" ]
then
    TAGNAME=${RPKI_RTR_SERVER}
fi

if [ -z "${DATADIR}" ]
then
    DATADIR=${HOME}/rpki-rtr/${TAGNAME}
fi

if [ ! -d "${DATADIR}" ]
then
    mkdir -p ${DATADIR} || fatal "Cannot mkdir -p ${DATADIR}"
fi

# generally want group read/write
umask 002

cd ${DATADIR}
${RTR_CLIENT} -v -p ${PORT} -h ${RPKI_RTR_SERVER} -l ##TMP >/dev/null
