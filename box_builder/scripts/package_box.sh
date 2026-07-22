#!/bin/bash

vagrant package \
  --base debian13-template \
  --output debian13.box

vagrant box add debian13 debian13.box
