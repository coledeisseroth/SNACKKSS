OUT_DIR=$1
COUNT_DIR=$2
CONDITIONS=$3

mkdir -p $OUT_DIR/average_control_readcounts $OUT_DIR/control_stdev_readcounts $OUT_DIR/zscores
for trio in $(cat $CONDITIONS | sed 's/\t/_/g' | sort -u); do
pertsample=$(echo $trio | cut -d_ -f1)
pert=$(echo $trio | cut -d_ -f2)
controls=$(echo $trio | cut -d_ -f3 | sed 's/;/\n/g' | sort -u)
if [ $(echo ${pertsample}_${pert}.txt | comm -12 - <(ls $OUT_DIR/zscores | sort -u) | wc -l) -gt 0 ]; then continue; fi
for sample in $controls; do cat $COUNT_DIR/$sample.txt; done | sort -k1,1 | awk 'BEGIN {FS = "\t"; gene=""; t = 0; n = 0} {if(gene != $1 && gene != ""){print gene "\t" t / n; t = 0; n = 0} gene = $1; t += $2; n += 1} END {if(gene != ""){print gene "\t" t / n}}' > $OUT_DIR/average_control_readcounts/${pertsample}_${pert}.txt
	for sample in $controls; do cat $COUNT_DIR/$sample.txt | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat $OUT_DIR/average_control_readcounts/${pertsample}_${pert}.txt | sort -t$'\t' -k1,1); done | sort -k1,1 | awk 'BEGIN {FS = "\t"; gene=""; t = 0; n = 0} {if(gene != $1 && gene != ""){print gene "\t" sqrt(t / n); t = 0; n = 0} gene = $1; t += ($2-$3)^2; n++} END {if(gene != ""){print gene "\t" sqrt(t / n)}}' > $OUT_DIR/control_stdev_readcounts/${pertsample}_${pert}.txt
cat $COUNT_DIR/$pertsample.txt | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat $OUT_DIR/average_control_readcounts/${pertsample}_${pert}.txt | sort -t$'\t' -k1,1) | sort -k1,1 | join -t$'\t' - <(cat $OUT_DIR/control_stdev_readcounts/${pertsample}_${pert}.txt | sort -t$'\t' -k1,1) | awk 'BEGIN {FS = "\t"} $4 != 0 {print $1 "\t" ($2 - $3) / $4}' > $OUT_DIR/zscores/${pertsample}_${pert}.txt
rm $OUT_DIR/average_control_readcounts/${pertsample}_${pert}.txt $OUT_DIR/control_stdev_readcounts/${pertsample}_${pert}.txt
done

