#!/bin/bash

for port in 19794 19795; do
    fuser -k -n tcp $port
done

rm -vf imap_server.pid
