wget https://ftp.ncbi.nlm.nih.gov/pubchem/Substance/Extras/SID-Synonym.gz

mkdir split_100K
cd split_100K
split -l 100000 <(zcat ../SID-Synonym.gz)
cd ..

mkdir split_100K_clean
for file in $(ls split_100K); do
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 0.1; done
python3 ../../src/clean_column.py split_100K/$file 1 | sort -u | sort -t$'\t' -k2,2 > split_100K_clean/$file &
done
while [ $(jobs | grep Running | wc -l) -gt 0 ]; do jobs; sleep 1; done

rm -r split_100K

