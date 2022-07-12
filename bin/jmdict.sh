#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

echo
echo 'Downloading jmdict.db'
curl 'https://github.com/ruslandoga/jp-sqlite/releases/download/jmdict/jmdict.db' -LO
