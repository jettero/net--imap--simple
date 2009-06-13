#!/bin/bash

fuser -k -n tcp 7000
rm -vf imap_server.pid
