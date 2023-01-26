#!/bin/bash

git status
git pull
now=$(date)
echo "$now" > version
git add version
git commit -m "updated version!"
git push
git status
