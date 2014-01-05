#!/bin/bash

wget -rnH -A.png --no-parent --cut-dirs=3 -P /mnt/external/barrel_data/quicklook_spectra/ http://sprg.ssl.berkeley.edu/~kyando/barrel/quicklook/fspc
wget -rnH -A.png --no-parent --cut-dirs=3 -P /mnt/external/barrel_data/quicklook_spectra/ http://sprg.ssl.berkeley.edu/~kyando/barrel/quicklook/sspc
