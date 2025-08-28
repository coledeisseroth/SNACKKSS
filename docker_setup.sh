#!/bin/bash
set -e

cd /app/corpora
bash BUILD.sh

cd /app/metadata
bash BUILD.sh

cd /app/study
bash BUILD.sh

cd /app/sample
bash BUILD.sh

cd /app/target
bash BUILD.sh

cd /app/control
bash BUILD.sh

cd /app/signature
bash BUILD.sh


