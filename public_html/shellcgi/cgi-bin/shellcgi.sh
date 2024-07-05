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
#------------------------------------------------------------
# Support script for shellcgi system
#------------------------------------------------------------
#
# Set your home directory for shellcgi system.
# This directory must be readable from httpd!
#
#  ${CGICTRL_HOMEDIR}/html/_screen_name_.html
#  ${CGICTRL_HOMEDIR}/resource/_resourcename_
#  ${CGICTRL_HOMEDIR}/tranpgm/_tranname_
#  ${CGICTRL_HOMEDIR}/tranres/_tranname_
#  ${CGICTRL_HOMEDIR}/usertran/_username_
#
CGICTRL_HOMEDIR=/home/m-ito/.shellcgi; export CGICTRL_HOMEDIR
#
# Set temporary directory for shellcgi system.
# This directory will be created by shellcgi.cgi automatically.
# You should not change CGICTRL_TMPDIR without understanding what you are doing!
#
CGICTRL_TMPDIR=/tmp/.shellcgi; export CGICTRL_TMPDIR
#
# Set YES to get access log or set NO to be careless about access log
#
CGICTRL_LOGGING=YES; export CGICTRL_LOGGING
#
# Set user name who is not authenticated
#
CGICTRL_NOAUTHENTICATEDUSER=anonymous; export CGICTRL_NOAUTHENTICATEDUSER
#
# Set maximum count for lock retry(1 retry is 1 second)
#
CGICTRL_MAXLOCKRETRY=180; export CGICTRL_MAXLOCKRETRY
#
# Set sweepday. Old spa and input which was created sweepday before will be sweeped.
#
CGICTRL_SWEEPDAY=2; export CGICTRL_SWEEPDAY
#------------------------------------------------------------
# Functions for shellcgi system
#------------------------------------------------------------
#
# Usage: startcgi
# Initialize environment for starting cgi procedure. 
# This gets input data into temporary file from environment value `QUERY_STRING' or stdin.
#
function startcgi {
	umask 077
	if [ ! -d "${CGICTRL_TMPDIR}" ]
	then
		mkdir "${CGICTRL_TMPDIR}"
		mkdir "${CGICTRL_TMPDIR}/spa"
		mkdir "${CGICTRL_TMPDIR}/input"
		mkdir "${CGICTRL_TMPDIR}/param"
		mkdir "${CGICTRL_TMPDIR}/log"
		mkdir "${CGICTRL_TMPDIR}/lock"
	fi
	CGICTRL_UNIQUEID="${REMOTE_ADDR}".`date +"%Y%m%d%H%M%S.%N"`."${RANDOM}".$$; export CGICTRL_UNIQUEID
	CGICTRL_INPUT="${CGICTRL_TMPDIR}/input/${CGICTRL_UNIQUEID}"; export CGICTRL_INPUT
	if [ "X${REQUEST_METHOD}" = "XGET" ]
	then
		echo "${QUERY_STRING}" >"${CGICTRL_INPUT}"
	else
		dd bs="${CONTENT_LENGTH}" count=1 >"${CGICTRL_INPUT}" 2>/dev/null
		CGICTRL_SEP=`cat "${CGICTRL_INPUT}" | head -1 | tr -d '\r'`; export CGICTRL_SEP
	fi
}
#
# Usage: endcgi
# Clear environment for cgi procedure. 
# This remove temporary files.
#
function endcgi {
	rm "${CGICTRL_INPUT}"
}
#
# Usage: newsessionid
# Get new sessionid string
#
function newsessionid {
	mkdir "${CGICTRL_TMPDIR}/spa/${CGICTRL_UNIQUEID}"
	echo "${CGICTRL_UNIQUEID}"
}
#
# Usage: getpgm transaction
# Get fullpath of cgi program related to transaction
#
function getpgm {
	tran="$1"
	pgm=`cat "${CGICTRL_HOMEDIR}/tranpgm/${tran}" | egrep -v '^#' | sed -e '/^$/d'`
	echo "${pgm}"
}
#
# Usage: sweepspa days
# Clear spa cleated at days before
#
function sweepspa {
	(
		day="$1"
		cd "${CGICTRL_TMPDIR}/spa/" || return
		CGICTRL_DELDAYTIME=`date --date="${day} day ago" +"%Y%m%d999999"`; export CGICTRL_DELDAYTIME
		/bin/ls -1 |\
		egrep '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'|\
		awk 'BEGIN{
			FS="."
		}
		{
			if ($5 <= ENVIRON["CGICTRL_DELDAYTIME"]){
				print
			}
		}
		END{
		}' |\
		xargs rm -fr
	)
}
#
# Usage: sweepinput days
# Clear input cleated at days before
#
function sweepinput {
	(
		day="$1"
		cd "${CGICTRL_TMPDIR}/input/" || return
		CGICTRL_DELDAYTIME=`date --date="${day} day ago" +"%Y%m%d999999"`; export CGICTRL_DELDAYTIME
		/bin/ls -1 |\
		egrep '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'|\
		awk 'BEGIN{
			FS="."
		}
		{
			if ($5 <= ENVIRON["CGICTRL_DELDAYTIME"]){
				print
			}
		}
		END{
		}' |\
		xargs rm -fr
	)
}
#
# Usage: getlogdir
# Get directory name for logging
#
function getlogdir {
	echo "${CGICTRL_TMPDIR}/log"
}
#
# Usage: isloggingmode
# Get current logging mode
#
function isloggingmode {
	if [ "X${CGICTRL_LOGGING}" = "XYES" ]
	then
		return 0
	else
		return 1
	fi
}
#
# Usage: lock transaction resource
# Make lock directory for resource
#
function lock {
	tran="$1"
	res="$2"
	if [ -f ${CGICTRL_HOMEDIR}/resource/${res} ]
	then
		mkdir "${CGICTRL_TMPDIR}/lock/${res}" 2>/dev/null || return 1
		echo "${CGICTRL_UNIQUEID}" >"${CGICTRL_TMPDIR}/lock/${res}/${tran}"
		return 0
	fi
	return 2
}
#
# Usage: unlock transaction resource
# Remove lock directory for resource
#
function unlock {
	tran="$1"
	res="$2"
	if [ -f ${CGICTRL_HOMEDIR}/resource/${res} ]
	then
		ssid=`cat "${CGICTRL_TMPDIR}/lock/${res}/${tran}" 2>/dev/null`
		if [ "X${ssid}" = "X${CGICTRL_UNIQUEID}" ]
		then
			rm -fr "${CGICTRL_TMPDIR}/lock/${res}" 2>/dev/null
			return 0
		fi
		return 1
	fi
	return 2
}
#
# Usage: lockall transaction
# Make lock directory for all resources which transaction use
#
function lockall {
	tran="$1"
	for i in `cat "${CGICTRL_HOMEDIR}/tranres/${tran}" 2>/dev/null | egrep -v '^#' | sed -e '/^$/d' | sort`
	do
		count=0
		lock ${tran} "$i"
		lockstat=$?
		count=`expr ${count} + 1`
		while [ ${lockstat} -ne 0 ]
		do
			if [ ${lockstat} -eq 2 ]
			then
				unlockall ${tran}
				return 2
			fi
			if [ ${count} -ge ${CGICTRL_MAXLOCKRETRY} ]
			then
				unlockall ${tran}
				return 1
			fi
			sleep 1
			lock ${tran} "$i"
			lockstat=$?
			count=`expr ${count} + 1`
		done
	done
	return 0
}
#
# Usage: unlockall transaction
# Remove lock directory for all resources which transaction use
#
function unlockall {
	tran="$1"
	ret=0
	for i in `cat "${CGICTRL_HOMEDIR}/tranres/${tran}" 2>/dev/null | egrep -v '^#' | sed -e '/^$/d' | sort`
	do
		unlock ${tran} "$i"
		if [ $? -ne 0 ]
		then
			ret=1
		fi
	done
	return "${ret}"
}
#
# Usage: showtimeover
# Show lock failure message in html
#
function showtimeover {
	echo "Content-Type: text/html"
	echo ""
	echo "Time over while executing ${CGICTRL_TRAN}."
}
#
# Usage: showresourceerror
# Show lock failure message in html
#
function showresourceerror {
	echo "Content-Type: text/html"
	echo ""
	echo "ResourceID error while excuting ${CGICTRL_TRAN}."
}
#------------------------------------------------------------
# Functions for user applications
#------------------------------------------------------------
#
# Usage: getvalue name
# Get value from input item on <form> and output it stdout.
# <input type="text">, <input type="file">, <textarea> etc are acceptable.
#
function getvalue {
	name="$1"
	CGICTRL_CR=`echo -e -n '\r'`; export CGICTRL_CR
	if [ "X`echo ${CONTENT_TYPE} | egrep 'multipart/form-data'`" = "X" ]
	then
		for i in `cat "${CGICTRL_INPUT}" | tr '&' ' '`
		do
			inname=`echo "$i" | cut -d= -f1`
			if [ "X${inname}" = "X${name}" ]
			then
				raw_value=`echo "$i" | cut -d= -f2 | sed -e 's/+/ /g;s/%/\\\\x/g'`
				printf "${raw_value}"
			fi
		done
	else
		start=0
		end=0
		for i in `cat "${CGICTRL_INPUT}" | egrep -a -n -e "${CGICTRL_SEP}" | cut -d: -f1`
		do
			if [ ${start} -eq 0 ]
			then
				start=`expr $i + 1`
			elif [ ${end} -eq 0 ]
			then
				end=`expr $i - 1`
			else
				start=`expr ${end} + 2`
				end=`expr $i - 1`
			fi
		
			if [ ${start} -ne 0 -a ${end} -ne 0 ]
			then
				res=`sed -n -e "${start},${end}p" "${CGICTRL_INPUT}" |\
					awk '{
						if ($0 ~ /^\r$/){
							exit;
						}else{
							print;
						}
					}' |\
					egrep "Content-Disposition:.* name=\"${name}\""`
				if [ "X${res}" != "X" ] 
				then
					bias=`sed -n -e "${start},${end}p" "${CGICTRL_INPUT}" |\
						awk 'BEGIN{
							count = 0;
						}
						{
							if ($0 ~ /^\r$/){
								count++;
								print count;
								exit;
							}else{
								count++;
							}
						}'`
					start2=`expr ${start} + ${bias}`
					(
						if [ ${start2} -eq ${end} ]
						then
							sed -n -e "${start2},${end}p" "${CGICTRL_INPUT}" |\
							sed -e "s/${CGICTRL_CR}$//" |\
							tr -d '\n'
						else
							end2=`expr ${end} - 1`
							sed -n -e "${start2},${end2}p" "${CGICTRL_INPUT}"
							sed -n -e "${end},${end}p" "${CGICTRL_INPUT}" |\
							sed -e "s/${CGICTRL_CR}$//" |\
							tr -d '\n'
						fi
					)
				fi
			fi
		done
	fi
}
#
# Usage: getfilename name
# Get filename from <input type="file"> on <form> and output it stdout.
#
function getfilename {
	name="$1"
	if [ "X`echo ${CONTENT_TYPE} | egrep 'multipart/form-data'`" = "X" ]
	then
		for i in `cat "${CGICTRL_INPUT}" | tr '&' ' '`
		do
			inname=`echo $i | cut -d= -f1`
			if [ "X${inname}" = "X${name}" ]
			then
				raw_value=`echo "$i" | cut -d= -f2 | sed -e 's/+/ /g;s/%/\\\\x/g'`
				printf "${raw_value}"
			fi
		done
	else
		start=0
		end=0
		for i in `cat "${CGICTRL_INPUT}" | egrep -a -n -e "${CGICTRL_SEP}" | cut -d: -f1`
		do
			if [ ${start} -eq 0 ]
			then
				start=`expr $i + 1`
			elif [ ${end} -eq 0 ]
			then
				end=`expr $i - 1`
			else
				start=`expr ${end} + 2`
				end=`expr $i - 1`
			fi
			if [ ${start} -ne 0 -a ${end} -ne 0 ]
			then
				res=`sed -n -e "${start},${end}p" "${CGICTRL_INPUT}" |\
					awk '{
						if ($0 ~ /^\r$/){
							exit;
						}else{
							print;
						}
					}' |\
					egrep "Content-Disposition:.* name=\"${name}\""`
				if [ "X${res}" != "X" ] 
				then
					echo "${res}" | sed -e 's/^.*filename="//;s/".*$//'
				fi
			fi
		done
	fi
}
#
# Usage: outhtml htmlfile name1=value1 name2=value2 ...
# Replace name to value in htmlfile and output it stdout.
#
# Only first htmlfile in cgi must be startted with next 2 lines.
# Content-Type: text/html<NewLine>
# <NewLine>
#
function outhtml {
	CGICTRL_PARAM="${CGICTRL_TMPDIR}/param/${CGICTRL_UNIQUEID}"; export CGICTRL_PARAM
	CGICTRL_PARAMSEP="${RANDOM}${RANDOM}${RANDOM}${RANDOM}"; export CGICTRL_PARAMSEP
	html="$1"
	echo "${CGICTRL_PARAMSEP}" >"${CGICTRL_PARAM}"
	echo "CGICTRL_SESSIONID" >>"${CGICTRL_PARAM}"
	echo "${CGICTRL_SESSIONID}" >>"${CGICTRL_PARAM}"
	outsw="off"
	while [ "$#" != "0" ]
	do
		if [ "X${outsw}" = "Xon" ]
		then
			echo "${CGICTRL_PARAMSEP}" >>"${CGICTRL_PARAM}"
			echo "$1" | head -1 | sed -e 's/=.*$//' >>"${CGICTRL_PARAM}"
			echo "$1" | head -1 | sed -e 's/^[^=]*=//' >>"${CGICTRL_PARAM}"
			echo "$1" | sed -n -e '2,$p' >>"${CGICTRL_PARAM}"
		else
			outsw="on"
		fi
        	shift
	done
	CGICTRL_START_REPLACE=`cat "${CGICTRL_HOMEDIR}/html/${html}" | expand | egrep '^# *START=' | cut -d'=' -f2 | cut -d' ' -f1`; export CGICTRL_START_REPLACE
	CGICTRL_END_REPLACE=`cat "${CGICTRL_HOMEDIR}/html/${html}" | expand | egrep '^# *END=' | cut -d'=' -f2 | cut -d' ' -f1`; export CGICTRL_END_REPLACE
	cat "${CGICTRL_HOMEDIR}/html/${html}" |\
	egrep -v '^#' |\
	awk 'BEGIN{
		start = "@{"
		if (ENVIRON["CGICTRL_START_REPLACE"] != ""){
			start = ENVIRON["CGICTRL_START_REPLACE"]
		}
		end = "}@"
		if (ENVIRON["CGICTRL_END_REPLACE"] != ""){
			end = ENVIRON["CGICTRL_END_REPLACE"]
		}
		count = -1
		ret = getline <ENVIRON["CGICTRL_PARAM"]
		while (ret == 1){
			if ($0 == ENVIRON["CGICTRL_PARAMSEP"]){
				ret = getline <ENVIRON["CGICTRL_PARAM"]
				count++;
				str1a1[count] = sprintf("%s%s%s", start,$0,end)
				str1a2[count] = sprintf("%s%s=[^%s]*%s", start,$0,end,end)
				str2a[count] = ""
			}else{
				gsub(/&/,"\\\\\\&amp;")
				gsub(/</,"\\\\\\&lt;")
				gsub(/>/,"\\\\\\&gt;")
				gsub(/\x27/,"\\\\\\&#39;")
				gsub(/"/,"\\\\\\&quot;")
				gsub(/\r$/,"")
				if (str2a[count] == ""){
					str2a[count] = $0
				}else{
					str2a[count] = sprintf("%s\n%s", str2a[count], $0)
				}
			}
			ret = getline <ENVIRON["CGICTRL_PARAM"]
		}
	}
	{
		for (i = 0; i <= count; i++){
			gsub(str1a1[i],str2a[i])
			gsub(str1a2[i],str2a[i])
		}
		s = sprintf("%s[^=%s]*%s",start,end,end)
		gsub(s,"")
		s = sprintf("%s[^=%s]*=",start,end)
		gsub(s,"")
		gsub(end,"")
		print
	}
	END{
	}'

	rm "${CGICTRL_PARAM}"
}
#
# Usage: getrealres resourceid
# Get real resouce in string
#
function getrealres {
	res="$1"
	realres=`cat "${CGICTRL_HOMEDIR}/resource/${res}" | egrep -v '^#' | sed -e '/^$/d'`
	echo "${realres}"
}
#
# Usage: getspa spaname
# Get value of spaname
#
function getspa {
	spaname="$1"
	value=`cat "${CGICTRL_TMPDIR}/spa/${CGICTRL_SESSIONID}/${spaname}" 2>/dev/null`
	echo "${value}"
}
#
# Usage: setspa spaname value
# Set spaname to value
#
function setspa {
	spaname="$1"
	value="$2"
	echo "${value}" >"${CGICTRL_TMPDIR}/spa/${CGICTRL_SESSIONID}/${spaname}"
}
#
# Usage: clearallspa
# Clear all spa in current session
#
function clearallspa {
	rm -f "${CGICTRL_TMPDIR}/spa/${CGICTRL_SESSIONID}"/*
}
#
# Usage: clearspa spaname
# Clear spaname in current session
#
function clearspa {
	spaname="$1"
	rm -f "${CGICTRL_TMPDIR}/spa/${CGICTRL_SESSIONID}/${spaname}"
}
#
# Usage: isoutputmode
# Get current output mode
#
function isoutputmode {
	if [ "X${CGICTRL_IOMODE}" = "Xoutput" ]
	then
		return 0
	else
		return 1
	fi
}
#
# Usage: isinputmode
# Get current input mode
#
function isinputmode {
	if [ "X${CGICTRL_IOMODE}" = "Xinput" ]
	then
		return 0
	else
		return 1
	fi
}
#
# Usage: getuser
# Get authenticated user name
#
function getuser {
	if [ -z "${REMOTE_USER}" ]
	then
		echo "${CGICTRL_NOAUTHENTICATEDUSER}"
	else
		echo "${REMOTE_USER}"
	fi
}
#
# Usage: settran transaction_name
# Set CGICTRL_TRAN in spa to transaction_name
#
function settran {
	tran="$1"
	setspa CGICTRL_TRAN "${tran}"
}
#
# Usage: gettran
# Get current transaction name
#
function gettran {
	getspa CGICTRL_TRAN
}
#
# Usage: ispermitted
# Check current user and current transaction are permitted
#
function ispermitted {
	user=`getuser`
	tran=`gettran`
	ispermittedwith "${user}" "${tran}"
	return $?
}
#
# Usage: ispermittedwith USER TRANSACTION
# Check specified user and ransaction are permitted
#
function ispermittedwith {
	user="$1"
	tran="$2"
	for i in `cat "${CGICTRL_HOMEDIR}/usertran/${user}" 2>/dev/null | egrep -v '^#' | sed -e '/^$/d'`
	do
		if [ `echo "${tran}" | egrep "$i"` ]
		then
			return 0
		fi
	done
	return 1
}
