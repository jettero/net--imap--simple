#!/bin/bash

export SUICIDE_SECONDS=3600
perl -Iblib/lib -w t/test_server.pm
