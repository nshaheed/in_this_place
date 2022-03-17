#!/bin/bash

rm -f release.zip

zip -r release.zip init.ck VideoController.ck CREnv.ck main.ck video_player concertina1.wav
