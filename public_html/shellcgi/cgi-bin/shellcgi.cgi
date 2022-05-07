#! /bin/sh
#
# Usage: <a href="./cgi-bin/shellcgi.cgi?inittran=_initial_transaction_name_">
#        <form action="./shellcgi.cgi" method="xxxx">
#
. ./shellcgi.sh
startcgi

sweepspa ${CGICTRL_SWEEPDAY}
sweepinput ${CGICTRL_SWEEPDAY}

CGICTRL_INITTRAN=`getvalue inittran`
if [ "X${CGICTRL_INITTRAN}" = "X" ]
then
	CGICTRL_SESSIONID=`getvalue CGICTRL_SESSIONID`; export CGICTRL_SESSIONID
	CGICTRL_TRAN=`getspa CGICTRL_TRAN`
else
	CGICTRL_SESSIONID=`newsessionid`; export CGICTRL_SESSIONID
	CGICTRL_TRAN="${CGICTRL_INITTRAN}"
	setspa CGICTRL_TRAN "${CGICTRL_INITTRAN}"
fi

if [ "X${CGICTRL_INITTRAN}" = "X" ]
then
	lockall "${CGICTRL_TRAN}"
	lockallstat=$?
	if [ ${lockallstat} -eq 1 ]
	then
		showtimeover
		exit 1
	elif [ ${lockallstat} -eq 2 ]
	then
		showresourceerror
		exit 1
	fi

	if [ `isloggingmode` ]
	then
		CGICTRL_LOGFILE=`getlogdir`/`date +"%Y%m%d"`.log
		(
			echo -n `date +"%Y/%m/%d,%H:%M:%S"`
			echo -n ",${REMOTE_ADDR},"`getuser`",input,"
			cat "${CGICTRL_INPUT}" | base64 | tr -d '\n' | sed -e 's/$/\n/'
		) >>"${CGICTRL_LOGFILE}"
	fi

	CGICTRL_CGIPGM=`getpgm "${CGICTRL_TRAN}"`
	CGICTRL_IOMODE="input"; export CGICTRL_IOMODE
	sh -c "${CGICTRL_CGIPGM}"
	unlockall "${CGICTRL_TRAN}"

	CGICTRL_TRAN=`getspa CGICTRL_TRAN`
fi

lockall "${CGICTRL_TRAN}"
lockallstat=$?
if [ ${lockallstat} -eq 1 ]
then
	showtimeover
	exit 1
elif [ ${lockallstat} -eq 2 ]
then
	showresourceerror
	exit 1
fi
CGICTRL_CGIPGM=`getpgm "${CGICTRL_TRAN}"`
CGICTRL_IOMODE="output"; export CGICTRL_IOMODE
if [ `isloggingmode` ]
then
	CGICTRL_LOGTMP1=`getlogdir`/"${CGICTRL_SESSIONID}".1
	CGICTRL_LOGTMP2=`getlogdir`/"${CGICTRL_SESSIONID}".2
	CGICTRL_LOGFILE=`getlogdir`/`date +"%Y%m%d"`.log
	echo -n `date +"%Y/%m/%d,%H:%M:%S"` >"${CGICTRL_LOGTMP1}"
	echo -n ",${REMOTE_ADDR},"`getuser`",output," >>"${CGICTRL_LOGTMP1}"
	sh -c "${CGICTRL_CGIPGM}" | tee "${CGICTRL_LOGTMP2}"
	(
		cat "${CGICTRL_LOGTMP1}"
		cat "${CGICTRL_LOGTMP2}" | base64 | tr -d '\n' | sed -e 's/$/\n/'
	) >>"${CGICTRL_LOGFILE}" && rm -f "${CGICTRL_LOGTMP1}" "${CGICTRL_LOGTMP2}"
else
	sh -c "${CGICTRL_CGIPGM}"
fi
unlockall "${CGICTRL_TRAN}"

endcgi
