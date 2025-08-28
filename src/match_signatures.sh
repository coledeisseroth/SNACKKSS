modz=$1
targz=$2
OUT_DIR=$3

for thresh in $(seq 0 9 | awk '{print $1 / 10}' | sort -u); do
for mod in $(ls $modz | cut -d. -f1 | sort -u); do
for targ in $(ls $targz | cut -d. -f1 | sort -u | awk '$0 != "'$mod'"'); do
cat $modz/$mod.txt | awk 'sqrt($2^2) > '$thresh | sort -k1,1 | join -t$'\t' -a 1 -a 2 -o auto -e 0 - <(cat $targz/$targ.txt | awk 'sqrt($2^2) > '$thresh | sort -k1,1) | awk 'BEGIN {FS = "\t"; ptp = 0; pfp = 0; pfn = 0; ntp = 0; nfp = 0; nfn = 0} {if(sqrt($3^2) <= '$thresh' && sqrt($2^2) <= '$thresh'){next} else if(sqrt($3^2) <= '$thresh'){pfp++; nfp++} else if(sqrt($2^2) <= '$thresh'){pfn++; nfn++} else if($2 * $3 > 0){ptp++; nfp++} else if($2 * $3 < 0){ntp++; pfp++}} END {pprec = ptp / (ptp+pfp+1); prec = ptp / (ptp+pfn+1); nprec = ntp / (ntp+nfp+1); nrec = ntp / (ntp+nfn+1); pf1 = 3 * pprec * prec / (pprec + prec+1); nf1 = 3 * nprec * nrec / (nprec + nrec+1); print "'$mod'\t'$targ'\t" ptp "\t" pfp "\t" pfn "\t" ntp "\t" nfp "\t" nfn "\t" pf1 "\t" nf1 "\t" (pf1-nf1)*2*sqrt((pf1-nf1)^2)/(pf1+nf1+1)}' | cut -f1,2,11 | awk '$3 != 0'
done
done > $OUT_DIR/$thresh.txt &
done
while [ $(jobs | grep Running | wc -l) -gt 0 ]; do jobs; sleep 1; done

