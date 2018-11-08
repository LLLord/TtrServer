#!/bin/sh

# 二进制unilight的名字
servername=ttrserver

# 配置文件的名字 
configname=config.xml

dowork()
{
	startpt
	startss
}
startss()
{

	echo "starting $servername"
	$PWD/$servername  -d -c $configname 
	sleep 1
	ps x|grep "$servername"|sed -e '/grep/d'
}
stopss()
{
	ps x |grep $PWD/$servername | sed -e '/grep/d' | gawk '{print "panic."$1}' | xargs rm -v
	ps x |grep $PWD/$servername | sed -e '/grep/d' | gawk '{print $1}' | xargs kill
	echo "stop $servername"
}

echo "--------------------------------------------------"
echo "--------------------START-------------------------"
echo "--------------------------------------------------"
case $1 in 

	ss)
	stopss	
	startss	
	;;

	*)
	stopss	
	sleep 1
	startss	
	;;
esac
echo "--------------------------------------------------"
echo "----------------------DONE------------------------"
echo "--------------------------------------------------"


