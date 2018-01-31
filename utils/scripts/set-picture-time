#!/bin/bash
# @depends on exiv2

if [ "$1" == "" ]; then
    echo "usage: $(basename $0) '2002:07:22 00:00:00' picture.jpg "
else
    exiv2 -M "set Exif.Photo.DateTimeOriginal $1" $2
fi

# vim: syntax=sh
