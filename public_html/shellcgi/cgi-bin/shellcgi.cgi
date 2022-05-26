#! /bin/sh
#
# shellcgi - Shell framework for CGI programming
# Copyright (C) 2022 "Masahiko Ito"<m-ito@myh.no-ip.org>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

	if isloggingmode
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
if isloggingmode
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
