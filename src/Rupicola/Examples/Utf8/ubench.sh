#/bin/sh
set -eu
cd "$(dirname "$0")"

( cd ../../../../
  COQFLAGS="${COQFLAGS:-"$(make -f Makefile.coqflags)"}" bedrock2/etc/bytedump.sh Rupicola.Examples.Utf8.Utf8.utf8_decode_cbytes
  ) > utf8_rupicola.h

CC="${CC:-cc}"

$CC -O3 -c utf8_skeeto.c
$CC -O3 ubench.c utf8_skeeto.o -lm -o ubench_skeeto

$CC -O3 -c utf8_client_rupicola.c
$CC -O3 ubench.c utf8_client_rupicola.o -lm -o ubench_rupicola

doas /usr/local/bin/turboboost-off.sh > /dev/null
doas /usr/local/bin/hyperthreading-off.sh > /dev/null

#doas /usr/bin/cpupower -c 2 frequency-set --freq "$(grep -o '[0-9\.]*GHz' /proc/cpuinfo | sort -h | head -1)"
doas /usr/bin/cpupower -c 2 frequency-set --governor performance
sleep 1
printf "utf8_rupicola: "; taskset -c 2 ./ubench_rupicola
printf "utf8_skeeto: "; taskset -c 2 ./ubench_skeeto
#doas /usr/bin/cpupower -c 2 frequency-set --governor schedutil

doas /usr/local/bin/hyperthreading-on.sh > /dev/null
doas /usr/local/bin/turboboost-on.sh > /dev/null
