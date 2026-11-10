#!/usr/bin/env bash
# Builds the installer package: redmine_persian_calendar.tar.gz
set -euo pipefail
cd "$(dirname "$0")/src"
tar czf ../redmine_persian_calendar.tar.gz --exclude='_redmine6_legacy' redmine_persian_calendar
echo "Built $(cd .. && pwd)/redmine_persian_calendar.tar.gz"
