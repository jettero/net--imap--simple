#!/bin/bash

export DEBUG=contrib.log

perl contrib/33189_attach.pl bct
perl contrib/hand_test01.pl  bct
