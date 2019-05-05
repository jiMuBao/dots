#! /bin/bash
BOOKMARK_LIST=/tmp/bookmarks_list
# put bookmark extraction code here
CHROME_BM="$HOME/.config/google-chrome/Default/Bookmarks"
  cat  $CHROME_BM | \
        tr "\012" " " | tr "{" "\012"          | \
        grep '"type": "url",'                  | \
        perl -e 'while(<>) {$_ =~ m/"name": "([^"]*)"/ ; $T = $1; m/"url": "([^"]*)"/ ; $U = $1; print "$T\t$U\n" if (($T) && ($U) && ($T ne $U )) }'  > $BOOKMARK_LIST
IFS=
while read LINE; do
TITLE=`echo $LINE | cut -f1`
URL=`echo $LINE | cut -f2`
wget -O/dev/null -q $URL && echo -n "STILL_ONLINE: " || echo -n 'DISAPPEARED : '
echo "$TITLE"
done < $BOOKMARK_LIST
exit
