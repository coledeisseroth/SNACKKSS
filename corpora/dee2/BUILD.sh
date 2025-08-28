wget https://dee2.io/mx/hsapiens_ke.tsv.bz2
wget https://dee2.io/mx/mmusculus_ke.tsv.bz2

bzcat hsapiens_ke.tsv.bz2 | cut -f1 | uniq > human_sample_list.txt
bzcat mmusculus_ke.tsv.bz2 | cut -f1 | uniq > mouse_sample_list.txt

mkdir human_chewed_1 mouse_chewed_1
for suffix in $(seq 0 9); do
bzcat hsapiens_ke.tsv.bz2 | awk 'BEGIN {FS = "\t"} substr($1, length($1)) == "'$suffix'" && substr($1, 0, 3) == "SRR"' | gzip -c > human_chewed_1/$suffix.txt.gz &
bzcat mmusculus_ke.tsv.bz2 | awk 'BEGIN {FS = "\t"} substr($1, length($1)) == "'$suffix'" && substr($1, 0, 3) == "SRR"' | gzip -c > mouse_chewed_1/$suffix.txt.gz &
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done

for species in human mouse; do
mkdir ${species}_chewed_2
for s1 in $(seq 0 9); do
for s2 in $(seq 0 9); do
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 1; done
zcat ${species}_chewed_1/$s1.txt | awk 'BEGIN {FS = "\t"} substr($1, length($1)-1) == "'${s2}${s1}'"' | gzip -c > ${species}_chewed_2/${s2}${s1}.txt.gz &
done
done
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done
rm -r human_chewed_1 mouse_chewed_1

for species in human mouse; do
mkdir ${species}_chewed_3
for s1 in $(seq 0 9); do
for s2 in $(seq 0 9); do
for s3 in $(seq 0 9); do
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 1; done
zcat ${species}_chewed_2/${s2}${s1}.txt | awk 'BEGIN {FS = "\t"} substr($1, length($1)-2) == "'${s3}${s2}${s1}'"' | gzip -c > ${species}_chewed_3/${s3}${s2}${s1}.txt.gz &
done
done
done
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done
rm -r human_chewed_2 mouse_chewed_2

for species in human mouse; do
cat ${species}_sample_list.txt | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../../metadata/$species/sample_srr.txt | sort -k2,2) | cut -f2 | sort -u > ${species}_gsm_list.txt
done

