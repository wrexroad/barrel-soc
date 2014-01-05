#!/bin/bash

#configure env vars
. /usr/local/cdf/bin/definitions.B
export JAVA_HOME; JAVA_HOME=/usr/lib/jvm/default-java
export CLASSPATH; export CLASSPATH=${CLASSPATH}:.:${CDF_JAVA}/classes/cdfjava.jar
export LD_LIBRARY_PATH; export LD_LIBRARY_PATH=.:${CDF_LIB}:${CDF_JAVA}/lib
export ANT_HOME=/home/barrel/ant
export PATH=${PATH}:${ANT_HOME}/bin

#run the cdf generator
cd /home/barrel/barrel-cdf-generator/build/jar/
java -jar cdf_gen.jar ini=default.ini  L=1,2 date=`date --date=YESTERDAY +\%y\%m\%d`
cp -r out/* /mnt/external/barrel_data/cdf/
