#!/bin/sh
for branch in /home/artifact/snapshot/*/
do
	echo -n "$branch hash-[0-3]: "
	find $branch -type d -depth 1 -mtime +30d -name "???????????????????????????????????????[0-3]" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch hash-[4-7]: "
	find $branch -type d -depth 1 -mtime +183d -name "???????????????????????????????????????[4-7]" -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[4-7]/arm -type d -depth 1 -mtime +45d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[4-7]/mips -type d -depth 1 -mtime +45d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[4-7]/i386 -type d -depth 1 -mtime +45d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[4-7]/powerpc -type d -depth 1 -mtime +45d -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch hash-[8-9a-b]: "
	find $branch -type d -depth 1 -mtime +30d -name "???????????????????????????????????????[8-9a-b]" -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[8-9a-b]/arm -type d -depth 1 -mtime +15d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[8-9a-b]/mips -type d -depth 1 -mtime +15d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[8-9a-b]/i386 -type d -depth 1 -mtime +15d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[8-9a-b]/powerpc -type d -depth 1 -mtime +15d -print0 | xargs -0 rm -r
	find $branch/???????????????????????????????????????[8-9a-b]/riscv -type d -depth 1 -mtime +15d -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch hash-[c-e]: "
	find $branch -type d -depth 1 -mtime +90d -name "???????????????????????????????????????[c-e]" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch hash-[f]: "
	find $branch -type d -depth 1 -mtime +365d -name "???????????????????????????????????????f" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch r?????[0-3]: "
	find $branch -type d -depth 1 -mtime +60d -name "r?????[0-3]" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch r?????[4-7]: "
	find $branch -type d -depth 1 -mtime +365d -name "r?????[4-7]" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch r?????8: "
	find $branch -type d -depth 1 -mtime +183d -name "r?????8" -print0 | xargs -0 rm -r
	echo "done"

	echo -n "$branch r?????9: "
	find $branch -type d -depth 1 -mtime +15d -name "r?????9" -print0 | xargs -0 rm -r
	echo "done"

done