#!/bin/sh

find /usr/local/init/ -type f -exec sh -c "( {} & )" \;
