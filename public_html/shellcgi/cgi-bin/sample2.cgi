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
	settran "SAMPLE1"
#-- USER CODING END
else
#
# This block edit screen from SPA and output it.
# Next transaction must be a transaction for this program.
#
#-- USER CODING START
	thistran=`gettran`
	search=`getspa search`
	inputfile=`getrealres "ETC_SHELLS"`
	result=`cat ${inputfile} | egrep "${search}"`
	setspa search "${search}"
	outhtml ${thistran}.html \
		"search=${search}" \
		"result=${result}"
		"message=" \
	settran "${thistran}"
#-- USER CODING END
fi
exit 0
