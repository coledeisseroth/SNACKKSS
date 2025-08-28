wget ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz
wget ftp://ftp.ncbi.nih.gov/gene/DATA/gene2ensembl.gz
for species in human mouse; do
speciesid=9606
if [ $(echo $species | grep mouse | wc -l) -gt 0 ]; then speciesid=10090; fi
zcat gene_info.gz | awk '$1 == '$speciesid | cut -f2,3,5,9,12,14 | sed 's/|/\t/g' | sort -u > ${species}_aliases_wide.txt
cat ${species}_aliases_wide.txt | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i += 1){print $1 "\t" $i}}' > ${species}_aliases_tall.txt
rm ${species}_aliases_wide.txt
python3 ../../src/clean_column.py ${species}_aliases_tall.txt 1 | awk '$2 != ""' | sort -u | sort -t$'\t' -k2,2 > ${species}_aliases_tall_clean.txt
rm ${species}_aliases_tall.txt
done

