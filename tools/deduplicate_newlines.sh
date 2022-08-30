#!/usr/bin/env bash

sed -i -zEe 's/\n\n+/\n\n/g' "$1"
