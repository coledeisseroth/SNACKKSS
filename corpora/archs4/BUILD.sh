if [ $(ls | grep human_gene_v2.5.h5 | wc -l) -lt 1 ]; then wget 'https://s3.dev.maayanlab.cloud/archs4/files/human_gene_v2.5.h5'; fi
if [ $(ls | grep mouse_gene_v2.5.h5 | wc -l) -lt 1 ]; then wget 'https://s3.dev.maayanlab.cloud/archs4/files/mouse_gene_v2.5.h5'; fi
if [ $(ls | grep human_correlation_v2.4.pkl | wc -l) -lt 1 ]; then wget 'https://s3.amazonaws.com/mssm-data/human_correlation_v2.4.pkl'; fi
if [ $(ls | grep mouse_correlation_v2.4.pkl | wc -l) -lt 1 ]; then wget 'https://s3.amazonaws.com/mssm-data/mouse_correlation_v2.4.pkl'; fi

if [ $(ls | grep human_gene_list.txt | wc -l) -lt 1 ]; then python3 src/archs4_gene_list.py human_gene_v2.5.h5 > human_gene_list.txt; fi
if [ $(ls | grep mouse_gene_list.txt | wc -l) -lt 1 ]; then python3 src/archs4_gene_list.py mouse_gene_v2.5.h5 > mouse_gene_list.txt; fi
if [ $(ls | grep human_sample_list.txt | wc -l) -lt 1 ]; then python3 src/archs4_sample_list.py human_gene_v2.5.h5 > human_sample_list.txt; fi
if [ $(ls | grep mouse_sample_list.txt | wc -l) -lt 1 ]; then python3 src/archs4_sample_list.py mouse_gene_v2.5.h5 > mouse_sample_list.txt; fi

if [ $(ls | grep human_correlation_table.txt | wc -l) -lt 1 ]; then python3 src/parse_correlations.py human_correlation_v2.4.pkl > human_correlation_table.txt; fi

if [ $(ls | grep mouse_correlation_table.txt | wc -l) -lt 1 ]; then python3 src/parse_correlations.py mouse_correlation_v2.4.pkl > mouse_correlation_table.txt; fi

for species in human mouse; do
python3 ../../src/clean_column.py <(cat ${species}_correlation_table.txt | head -1 | sed 's/\t/\n/g' | awk 'NR > 1 {print $0 "\t" NR "\t" $0}') 0 | sort -k1,1 | join -t$'\t' -1 1 -2 2 - <(cat ../entrez/${species}_aliases_tall_clean.txt | sort -k2,2) | cut -f2- | sort -u > ${species}_column_gene_entrez.txt
done

