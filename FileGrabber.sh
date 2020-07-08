#!/bin/bash
#############################################################################################################
By: Husnain
Email: husnain114@gmail.com
##############################################################################################################
HNAME=$(hostname)
LOCAL_CONNECTION_IP="127.0.0.1"
SUCCESS_TEST="SUCCESS_TEST.out"
FAIL_TEST="CONNECTION_TEST.out"
FILE_SUFFIX_TYPE="*.txt"
STP=0
LOCAL_LOG="local_log.out"
MY_DIR="$(pwd)"
COMPDIR="/var/tmp"
CHKDIR="/var/tmp"

cat REMOTE_FILES_GRABBER.txt | grep -iv ^"#" > REMOTE_FILES_GRABBER.txt.tmp
sed -i '/^$/d' REMOTE_FILES_GRABBER.txt.tmp

input="REMOTE_FILES_GRABBER.txt.tmp"
while IFS=' ' read -r TANENTNAME TAGNAME MYLOCATIONS REMOTE_CONNECTION_IP REMPTE_CONNECTION_PORT REMOTE_CONNECTION_USER MYLOCATIONS_LOCAL PARSE_FILES LOCAL_DB_INSERT SYSLOGDBNAME SYSLOGPORT
do

mkdir -p ${MYLOCATIONS_LOCAL}/OUTFILES-$TANENTNAME-$TAGNAME

OUTFILE_LOCALE="${MYLOCATIONS_LOCAL}/OUTFILES-$TANENTNAME-$TAGNAME"

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "**********SFTP Session Activated: ${MYLOCATIONS}***************"

ERR=1
MAX_TRIES=4
for (( i=1; i<=$MAX_TRIES; i++ ))
   do
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO[CONN]:" "$REMOTE_CONNECTION_IP - Connection Check - Status: Attempt($i)"

ping -q -c 1 -W 1 "${REMOTE_CONNECTION_IP}" >/dev/null

if [ "$?" == "0" ]; then

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO[CONN]:" "$REMOTE_CONNECTION_IP - Connection Check - Status: Success($i)"
break;
else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR[CONN]:" "$REMOTE_CONNECTION_IP - Connection Check - Status: FAILED($i)"
sleep 5
if [ "${i}" -eq "4" ];
then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR[CONN]:" "$REMOTE_CONNECTION_IP - Connection Check - Retry expired"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR[CONN]:" "Script Status: Exit 0"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "**********SFTP Session ENDED******************************************************"
#rm -rf /tmp/myscript.running
#rm -rf /var/log/sipploggerP.lck
exit 0
fi
fi
done


if [ "${REMOTE_CONNECTION_USER}" != "" ];then

/usr/bin/sftp -p ${REMOTE_CONNECTION_PORT} -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >/dev/null 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR

cd ${MYLOCATIONS}
quit

EOF_TEST_DIR

DO_TEST=$(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST | grep -i "No such file or directory" | wc -l)
if [[ "${DO_TEST}" != "1" || "${DO_TEST}" < "1" ]];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "${MYLOCATIONS} is available on ${REMOTE_CONNECTION_IP}"

if [ -d "${MYLOCATIONS_LOCAL}" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "${MYLOCATIONS_LOCAL} is available on ${LOCAL_CONNECTION_IP}"
else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "${MYLOCATIONS_LOCAL} is not available on ${LOCAL_CONNECTION_IP}"
mkdir -p "${MYLOCATIONS_LOCAL}"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "${MYLOCATIONS_LOCAL} is generated on ${LOCAL_CONNECTION_IP}"
fi

if [ ! -f "$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed" ];then
touch $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed
fi

if [ ! -f "$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-failed" ];then
touch $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-failed
fi



if [ ! -s "$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed" ];
then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "Initiating first run for TANENT:${TANENTNAME} TAGNAME:${TAGNAME}"

/usr/bin/ssh -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
cd ${MYLOCATIONS}
ls -ltr *.txt | tail -1
exit
EOF_TEST_DIR

for GRABFILES in $(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out | grep -iv ^"$" | awk -F" " '{print $9}')
do

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-INIT"
/usr/bin/sftp -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-PROGRESS.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
lcd ${MYLOCATIONS_LOCAL}
cd ${MYLOCATIONS}
progress
get $GRABFILES
exit
EOF_TEST_DIR

if [ -f "${MYLOCATIONS_LOCAL}/$GRABFILES" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-FINI"
echo "$GRABFILES" > $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed

if [[ "${PARSE_FILES}" == "yes" || "${PARSE_FILES}" == "YES" ]];then

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER-YES: INIT"
awk 'NF > 0' ${MYLOCATIONS_LOCAL}/$GRABFILES > ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp
while IFS= read -r line
do
logger -t "$TAGNAME" "$line"
done < ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp
rm -rf ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER-YES: FINI"

else

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER: NO"

fi


else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-FAILED"
echo "$GRABFILES" >> $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-failed
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:MARKED-GRABBER-RERUN"
fi

done

elif [ -s "$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed" ];
then

LAST_PROCESSED_FILES=$(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed | grep -iv ^"$" | awk -F" " '{print $1}')

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "Locating new log files for TANENT:${TANENTNAME} TAGNAME:${TAGNAME}"

/usr/bin/ssh -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
cd ${MYLOCATIONS}
ls -ltr $LAST_PROCESSED_FILES
exit
EOF_TEST_DIR

LAST_FILE_EXISTS=$(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST | grep -iv ^"$" | grep -i "No such file or directory" | wc -l)

if [ "${LAST_FILE_EXISTS}" == "0" ];then

/usr/bin/ssh -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
cd ${MYLOCATIONS}
find *.txt -newer $LAST_PROCESSED_FILES
exit
EOF_TEST_DIR

FILES_TO_PROCESS=$(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out | grep -i "txt" | wc -l)

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILES_TO_PROCESS:$FILES_TO_PROCESS"

for NEWLOGFILES in $(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out | grep -iv ^"$" | awk -F" " '{print $1}')
do

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME:$NEWLOGFILES STATE:DOWNLOADING-INIT"
/usr/bin/sftp -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-PROGRESS.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
lcd ${MYLOCATIONS_LOCAL}
cd ${MYLOCATIONS}
progress
get $NEWLOGFILES
exit
EOF_TEST_DIR

if [ -f "${MYLOCATIONS_LOCAL}/$NEWLOGFILES" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME:$NEWLOGFILES STATE:DOWNLOADING-FINI"
echo "$NEWLOGFILES" > $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed



if [[ "${PARSE_FILES}" == "yes" || "${PARSE_FILES}" == "YES" ]];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $NEWLOGFILES LOG-PARSER-YES: INIT"
awk 'NF > 0' ${MYLOCATIONS_LOCAL}/$NEWLOGFILES > ${MYLOCATIONS_LOCAL}/$NEWLOGFILES.tmp
while IFS= read -r line
do
logger -t "$TAGNAME" "$line"
done < ${MYLOCATIONS_LOCAL}/$NEWLOGFILES.tmp
rm -rf ${MYLOCATIONS_LOCAL}/$NEWLOGFILES.tmp
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $NEWLOGFILES LOG-PARSER-YES: FINI"
else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $NEWLOGFILES LOG-PARSER: NO"
fi


else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME:$NEWLOGFILES STATE:DOWNLOADING-FAILED"
echo "$NEWLOGFILES" >> $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-failed
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME:$NEWLOGFILES STATE:MARKED-GRABBER-RERUN"
fi

done

elif [ "${LAST_FILE_EXISTS}" != "0" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILES_TO_PROCESS:$FILES_TO_PROCESS STATE:UNAVAIL"

/usr/bin/ssh -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
cd ${MYLOCATIONS}
ls -ltr *.txt
exit
EOF_TEST_DIR

for GRABFILES in $(cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-LISTFILES.out | grep -iv ^"$" | awk -F" " '{print $9}')
do

echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-INIT"
/usr/bin/sftp -o User="${REMOTE_CONNECTION_USER}" ${REMOTE_CONNECTION_IP} >$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-PROGRESS.out 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
lcd ${MYLOCATIONS_LOCAL}
cd ${MYLOCATIONS}
progress
get $GRABFILES
exit
EOF_TEST_DIR

if [ -f "${MYLOCATIONS_LOCAL}/$GRABFILES" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-FINI"
echo "$GRABFILES" > $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-processed


if [[ "${PARSE_FILES}" == "yes" || "${PARSE_FILES}" == "YES" ]];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER-YES: INIT"
awk 'NF > 0' ${MYLOCATIONS_LOCAL}/$GRABFILES > ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp
while IFS= read -r line
do
logger -t "$TAGNAME" "$line"
done < ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp
rm -rf ${MYLOCATIONS_LOCAL}/$GRABFILES.tmp
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER-YES: FINI"
else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES LOG-PARSER: NO"
fi



else
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:DOWNLOADING-FAILED"
echo "$GRABFILES" >> $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-last-failed
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "TANENT:${TANENTNAME} TAGNAME:${TAGNAME} FILENAME: $GRABFILES STATE:MARKED-GRABBER-RERUN"
fi

done


fi




echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "**********SFTP Session ENDED******************************************************"
fi










elif [[ "${DO_TEST}" == "1" || "${DO_TEST}" > "1" ]];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "Unable to reach "${MYLOCATIONS}" on ${REMOTE_CONNECTION_IP}"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "Please check ${REMOTE_CONNECTION_IP} and try again!"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "**********SFTP Session ENDED******************************************************"
#rm -rf /tmp/myscript.running
#break;
#exit 1
fi

else
/usr/bin/sftp -o Port=${REMOTE_CONNECTION_PORT} ${REMOTE_CONNECTION_IP} >/dev/null 2>$OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST <<EOF_TEST_DIR
cd ${MYLOCATIONS}
quit
EOF_TEST_DIR
DO_TEST=$(/bin/cat $OUTFILE_LOCALE/${TANENTNAME}-${TAGNAME}-$FAIL_TEST | grep -i "No such file or directory" | wc -l)
if [ "${DO_TEST}" != "1" ] || [ "${DO_TEST}" < "1" ];
then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "${MYLOCATIONS} is available on ${REMOTE_CONNECTION_IP}"
elif [ "${DO_TEST}" == "1" ] || [ "${DO_TEST}" > "1" ];then
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "Unable to reach "${MYLOCATIONS}" on ${REMOTE_CONNECTION_IP}"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-ERROR:" "Please check ${REMOTE_CONNECTION_IP} and try again!"
echo "[`date`]" "$HNAME syslog_grabber[]: MSGFCHK-INFO:" "**********SFTP Session ENDED******************************************************"
#rm -rf /tmp/myscript.running
#exit 1
#break;
fi

fi

done < "$input"
rm -rf REMOTE_FILES_GRABBER.txt.tmp

