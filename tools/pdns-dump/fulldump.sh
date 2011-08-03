#!/bin/bash
#

rm fulldump
FILEDUMP="/home/adulau/fulldump.pdns"
FILTER="*"
redis-cli KEYS "s:${FILTER}" | while read LINE; do echo -n $LINE." = ">>${FILEDU
MP}; VAL=`redis-cli GET ${LINE}`; echo "$VAL">>${FILEDUMP}; done;
redis-cli KEYS "l:${FILTER}" | while read LINE; do echo -n $LINE." = ">>${FILEDU
MP}; VAL=`redis-cli GET ${LINE}`; echo "$VAL">>${FILEDUMP}; done;
redis-cli KEYS "o:${FILTER}" | while read LINE; do echo -n $LINE." = ">>${FILEDU
MP}; VAL=`redis-cli GET ${LINE}`; echo "$VAL">>${FILEDUMP}; done;
redis-cli KEYS "r:${FILTER}" | while read LINE; do echo -n $LINE." = ">>${FILEDU
MP}; VAL=`redis-cli --raw -d , SMEMBERS ${LINE}`; echo "$VAL">>${FILEDUMP}; done
;

FILTER="*"
redis-cli KEYS "v:${FILTER}" | while read LINE; do echo -n $LINE." = ">>${FILEDU
MP}; VAL=`redis-cli --raw -d , SMEMBERS ${LINE}`; echo "$VAL">>${FILEDUMP}; done
;


