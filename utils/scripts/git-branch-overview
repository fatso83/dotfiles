#!/bin/sh

git branch $@ | sed 's/^..//' | xargs -L1 -IXX git log -n1 --pretty=format:'%d %s (%cr) <%an>'  XX --
