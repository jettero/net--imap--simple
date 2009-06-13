#!/bin/bash

./stop_server.sh

export SUICIDE_SECONDS=3600
perl -Iblib/lib -w t/test_server.pm
