#!/bin/bash
# $Id: upgrade.sh,v 1.10.2 2015/01/16 15:11:12 inureyes Exp $
# Original script for moniwiki by wkpark. Modified for Textcube by inureyes

CHECKSUM=
PACKAGE=Textcube
REMOTESOURCE=https://github.com/Needlworks/Textcube/archive/v
UPDATE=-1.10

if [ -z "$1" ]; then
	cat <<HELP
$PACKAGE upgrade script
-----------------------

Usage: $0 <version number>   (for manual download)

       e.g.): $0 1.10.2      (upgrades current $PACKAGE to 1.10.2)

 * If upgrade archive is located at the root directory of $PACKAGE, this script will use that.
 * If no file is prepared, script will download source file from $REMOTESOURCE.
 * If archive contains new upgrade script,

HELP
	exit 0
fi

SUCCESS="echo -en \\033[1;32m"
FAILURE="echo -en \\033[1;31m"
WARNING="echo -en \\033[1;33m"
MESSAGE="echo -en \\033[1;34m"
NORMAL="echo -en \\033[0;39m"
MAGENTA="echo -en \\033[1;35m"

NAME="Textcube"

$SUCCESS
export UNAME="`uname`"
if [[ "$UNAME" == 'Linux' ]]; then
	platform='linux'
	MD5SCRIPT='md5sum'
elif [[ "$UNAME" == 'Darwin' ]]; then
	platform='macosx'
	MD5SCRIPT='gmd5sum'
fi
echo "+---------------------------------------+"
echo "|        $NAME upgrade script        |"
echo "+---------------------------------------+"
echo "|  This script compare all files        |"
echo "| between current source and new ones.  |"
echo "|                                       |"
echo "|  All different files will be backuped |"
echo "| to the 'backup' directory. After upg- |"
echo "| rade, you can restore old files from  |"
echo "| backups manually.                     |"
echo "+---------------------------------------+"
echo
$WARNING
echo -n " Press "
$MAGENTA
echo -n ENTER
$WARNING
echo -n " to continue or "
$MAGENTA
echo -n Control-C
$WARNING
echo -n " to exit "
$NORMAL
read

for arg; do

        case $# in
        0)
                break
                ;;
        esac

        option=$1
        shift

        case $option in
        -show|-s)
		show=1
                ;;
	*)
		TAR=$option
	esac
done
TAR=$TAR.tar.gz
if ! [ -f $TAR ];
then
    if [ x$TAR != xauto ] ;
    then
        $FAILURE
        echo
        echo -n $TAR
        echo " does not exist."
    fi
    $WARNING
    echo -n " Do you want to download from remote repository (y/N)?  "
    $NORMAL
	read YES
	if [ x$YES != xy ]; then
		$NORMAL
		exit;
	fi
	REMOTESOURCEURL=$REMOTESOURCE$TAR
    $MESSAGE
    echo " -- Downloading package from remote repository "
    echo
    echo $REMOTESOURCEURL
    wget $REMOTESOURCEURL -O ./$TAR
    if ! [ -f $TAR ];
    then
        $FAILURE
        echo " Download Failed. Now quit."
        $NORMAL
        exit;
    fi
fi

#
TMP=.tmp$$
$MESSAGE
echo " -- Extracting tarball..."
$NORMAL
mkdir -p $TMP/$PACKAGE
echo tar xzf $TAR --strip-components=1 -C$TMP/$PACKAGE
tar xzf $TAR --strip-components=1 -C$TMP/$PACKAGE
$MESSAGE

echo " -- Check new upgrade.sh script from package..."
DIFF=
[ -f $TMP/$PACKAGE/upgrade.sh ] && DIFF=$(diff $0 $TMP/$PACKAGE/upgrade.sh)
if [ ! -z "$DIFF" ]; then
	$FAILURE
	echo "WARN: new upgrade.sh script found ***"
	$NORMAL
	cp -f $TMP/$PACKAGE/upgrade.sh up.sh
	$WARNING
	echo " new upgrade.sh file was copied as 'up.sh'"
	echo " Please execute following command"
	echo
	$MAGENTA
	echo " sh up.sh $TAR"
	echo
	$WARNING
	echo -n "Ignore it and try to continue ? (y/N) "
	read YES
	if [ x$YES != xy ]; then
		rm -r $TMP
		$NORMAL
		exit;
	fi
fi

$MESSAGE
echo " -- Making the checksum list for the new version..."
$NORMAL

FILELIST=$(find $TMP/$PACKAGE -type f | sort | sed "s@^$TMP/$PACKAGE/@@")

rm -f checksum-new
(cd $TMP/$PACKAGE; for x in $FILELIST; do test -f $x && $MD5SCRIPT $x;done >> ../../checksum-new)

if [ ! -f "$CHECKSUM" ];then
	rm -rf checksum-current
	$MESSAGE
	echo " -- Making the checksum list for currently installed version..."
	$NORMAL
	for x in $FILELIST; do test -f $x && $MD5SCRIPT $x;done >> checksum-current
	CHECKSUM=checksum-current
fi

UPGRADE=`diff checksum-current checksum-new |grep '^<'|cut -d' ' -f4`
NEW=`diff checksum-current checksum-new |grep '^\(<\|>\)' | cut -d' ' -f4|sort |uniq`

if [ -z "$UPGRADE" ] && [ -z "$NEW" ] ; then
	rm -r $TMP
	rm -f checksum-new checksum-current
	$FAILURE
	echo "You have already installed the latest version"
	$NORMAL
	exit
fi
$MESSAGE
echo " -- Backup old files..."
$NORMAL

$WARNING
echo -n " What type of backup do you want to ? ("
$MAGENTA
echo -n B
$WARNING
echo -n "ackup(default)/"
$MAGENTA
echo -n t
$WARNING
echo -n "ar/"
$MAGENTA
echo -n p
$WARNING
echo "atch) "
$NORMAL

echo "   (Type 'B/t/p')"
read TYPE

DATE=`date +%Y%m%d-%s`
if [ x$TYPE != xt ] && [ x$TYPE != xp ] ; then
        BACKUP=backup/$DATE
else
        BACKUP=$TMP/$PACKAGE-$DATE
fi
$MESSAGE

if [ ! -z "$UPGRADE" ]; then
	echo "*** Backup the old files ***"
	$NORMAL
	mkdir -p backup
	mkdir -p $BACKUP
	tar cf - $UPGRADE|(cd $BACKUP;tar xvf -)

	if [ x$TYPE = xt ]; then
		SAVED="backup/$DATE.tar.gz"
        	(cd $TMP; tar czvf ../backup/$DATE.tar.gz $PACKAGE-$DATE)
        	$MESSAGE
        	echo "   Old files are backuped as a backup/$DATE.tar.gz"
        	$NORMAL
	elif [ x$TYPE = xp ]; then
		SAVED="backup/$PACKAGE-$DATE.diff"
        	(cd $TMP; diff -ruN $PACKAGE-$DATE $PACKAGE > ../backup/$PACKAGE-$DATE.diff )
        	$MESSAGE
        	echo "   Old files are backuped as a backup/$PACKAGE-$DATE.diff"
        	$NORMAL
	else
		SAVED="$BACKUP/ dir"
        	$MESSAGE
        	echo "   Old files are backuped to the $SAVED"
        	$NORMAL
	fi
else
	$WARNING
	echo " You don't need to backup files !"
	$NORMAL
fi

$WARNING
echo " Are your really want to upgrade $PACKAGE ?"
$NORMAL
echo -n "   (Type '"
$MAGENTA
echo -n yes
$NORMAL
echo -n "' to upgrade or type others to exit)  "
read YES
if [ x$YES != xyes ]; then
	rm -r $TMP
	echo -n "Please type '"
	$MAGENTA
	echo -n yes
	$NORMAL
	echo "' to real upgrade"
	exit -1
fi
(cd $TMP/$PACKAGE;tar cf - $NEW|(cd ../..;tar xvf -))
rm -r $TMP
$SUCCESS
echo
echo "  $NAME is successfully upgraded."
echo "-------------------------------------------"
echo "  All different files are backuped in the"
echo "  $SAVED now. :)"
$NORMAL
