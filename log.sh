#!/bin/sh


CONFIG="config.xml"

main()
{
 	LOG=`grep ttrserver.log $CONFIG |sed -e 's/<[a-zA-Z]*>//'|sed -e 's/<\/[a-zA-Z]*>//'|sed -e 's/\r//'`

	tail --follow=name --retry $LOG --max-unchanged-stats=3 -n 5 -q | awk '/INFO/ {print "\033[32m" $0 "\033[39m"} /DEBUG/ {print  $0 }  /WARNING/ {print "\033[33m" $0 "\033[39m"} /    TRACE/ {print "\033[33m" $0 "\033[39m"} /ERROR/ {print "\033[31m" $0 "\033[39m"}'	
}
main 
