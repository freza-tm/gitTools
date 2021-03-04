#!/bin/bash
find -type d -name obj -not -path "./packages/*" -print0 | xargs -0 rm -rf
