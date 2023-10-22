#!/bin/sh
for branch in /home/artifact/snapshot/*/
do
	echo -n "$branch hash-[0-3]: "
	find $branch -type d -depth 1 -mtime +60d -name "???????????????????????????????????????[0-3]" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch hash-[4-7]: "
	find $branch -type d -depth 1 -mtime +183d -name "???????????????????????????????????????[4-7]" -print0 | xargs -0 -n 1 echo | wc -l
	find $branch/????????????????????????????????????????/arm -type d -depth 1 -mtime +45d -print0 | xargs -0 -n 1 echo | wc -l
	find $branch/????????????????????????????????????????/mips -type d -depth 1 -mtime +45d -print0 | xargs -0 -n 1 echo | wc -l
	find $branch/????????????????????????????????????????/i386 -type d -depth 1 -mtime +45d -print0 | xargs -0 -n 1 echo | wc -l
	find $branch/????????????????????????????????????????/powerpc -type d -depth 1 -mtime +45d -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch hash-[8-9a-b]: "
	find $branch -type d -depth 1 -mtime +60d -name "???????????????????????????????????????[8-9a-b]" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch hash-[c-e]: "
	find $branch -type d -depth 1 -mtime +90d -name "???????????????????????????????????????[c-e]" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch hash-[f]: "
	find $branch -type d -depth 1 -mtime +365d -name "???????????????????????????????????????f" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch r?????[0-3]: "
	find $branch -type d -depth 1 -mtime +60d -name "r?????[0-3]" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch r?????[4-7]: "
	find $branch -type d -depth 1 -mtime +365d -name "r?????[4-7]" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch r?????8: "
	find $branch -type d -depth 1 -mtime +183d -name "r?????8" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

	echo -n "$branch r?????9: "
	find $branch -type d -depth 1 -mtime +15d -name "r?????9" -print0 | xargs -0 -n 1 echo | wc -l
	echo "done"

done