#! /bin/sh
. ./shellcgi.sh
#-- USER CODING START
#-- USER CODING END
if isinputmode
then
#
# This block processes input data from FORM or SPA and determine next transaction which create screen.
#
#-- USER CODING START
	search=`getvalue search`
	if [ "X${search}" = "X" ]
	then
		setspa search "${search}"
		setspa message "検索文字列が指定されていません"
		setspa msgcolor "red"
		settran "SAMPLE1"
	else
		user=`getuser`
		if ispermittedwith "${user}" SAMPLE2
		then
			setspa search "${search}"
			setspa message ""
			setspa msgcolor "black"
			settran "SAMPLE2"
		else
			setspa search "${search}"
			setspa message "${user}は結果の表示を許可されていません"
			setspa msgcolor "red"
			settran "SAMPLE1"
		fi
	fi
#-- USER CODING END
else
#
# This block edit screen from SPA and output it.
# Next transaction must be a transaction for this program.
#
#-- USER CODING START
	thistran=`gettran`
	search=`getspa search`
	message=`getspa message`
	msgcolor=`getspa msgcolor`
	outhtml ${thistran}.html \
		"search=${search}" \
		"message=${message}" \
		"msgcolor=${msgcolor}"
	settran "${thistran}"
#-- USER CODING END
fi
exit 0
