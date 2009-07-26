#!/bin/bash

for port in 7000 8000 9000; do
    fuser -k -n tcp $port
done

rm -vf imap_server.pid
