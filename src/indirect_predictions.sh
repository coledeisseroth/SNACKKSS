f1=$1
corr_id_mapping=$2
correlations=$3
OUT_DIR=$4

for thresh in $(seq 0 9 | awk '{print $1 / 10}'); do
for targ in $(cat $corr_id_mapping | cut -f3 | sort -u); do
index=$(cat $corr_id_mapping | awk '$3 == "'$targ'"' | cut -f1 | sort -gu | head -1)
cat $correlations | cut -f1,$index | sort -t$'\t' -k1,1 | join -t$'\t' -1 3 -2 1 <(cat $f1/$thresh.txt | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat $corr_id_mapping | cut -f2- | sort -t$'\t' -k2,2) | cut -f2- | sort -t$'\t' -k3,3) - | awk '$3 * $4 != 0 {print $2 "_'$targ'\t" $3 * $4 / (sqrt($3^2)+sqrt($4^2))}' | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; p = 0; n = 0} {if(cur != "" && cur != $1 && p - n != 0){print cur "\t" (p-n)*sqrt((p-n)^2)/(p+n); p = 0; n = 0} cur = $1; if($2 > 0){p += $2} else{n -= $2}} END {print cur "\t" (p-n)*sqrt((p-n)^2)/(p+n)}' | sed 's/_/\t/g'
done > $OUT_DIR/$thresh.txt &
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done

