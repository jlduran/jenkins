#!/bin/sh

pw groupadd artifact -g 1000
pw useradd -n artifact -u 1000 -c "artifact owner" -g 1000 -w no -s ""
