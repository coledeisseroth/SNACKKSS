#rm -rf gene drug
#Customize the control lists to those with samples in each read-count dataset
#for pert in gene drug; do
#mkdir -p $pert
#for species in human mouse; do
#cat ../control/$pert/sample_pert_controls.txt | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/archs4/${species}_sample_list.txt | sort -u) | awk '{gsub(";", "\t", $3); print $1 "_" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/archs4/${species}_sample_list.txt | sort -u) | sort -u | sort -k2,2 -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; samples = ""} {if(cur != "" && cur != $2){print cur "\t" samples; samples = ""} cur = $2; samples = samples ";" $1} END {print cur "\t" samples}' | sed 's/\t;/\t/g' | sed 's/_/\t/g' | awk '$1 != ""' > $pert/archs4_${species}_sample_controls.txt
#cat ../control/$pert/sample_pert_controls.txt | sort -t$'\t' -k1,1 | join -t$'\t' <(cat ../metadata/${species}/sample_srr.txt | sort -k1,1) - | cut -f2- | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/recount3/${species}_srp_to_srr.txt | cut -f2 | sort -u) | awk '{gsub(";", "\t", $3); print $1 "_" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -t$'\t' -k1,1 | join -t$'\t' <(cat ../metadata/$species/sample_srr.txt | sort -t$'\t' -k1,1) - | cut -f2- | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/recount3/${species}_srp_to_srr.txt | cut -f2 | sort -u) | sort -u | sort -k2,2 -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; samples = ""} {if(cur != "" && cur != $2){print cur "\t" samples; samples = ""} cur = $2; samples = samples ";" $1} END {print cur "\t" samples}' | sed 's/\t;/\t/g' | sed 's/_/\t/g' | awk '$1 != ""' > $pert/recount3_${species}_sample_controls.txt
#cat ../control/$pert/sample_pert_controls.txt | sort -t$'\t' -k1,1 | join -t$'\t' <(cat ../metadata/$species/sample_srr.txt | sort -k1,1) - | cut -f2- | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/dee2/${species}_sample_list.txt | sort -u) | awk '{gsub(";", "\t", $3); print $1 "_" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -t$'\t' -k1,1 | join -t$'\t' <(cat ../metadata/$species/sample_srr.txt | sort -t$'\t' -k1,1) - | cut -f2- | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat ../corpora/dee2/${species}_sample_list.txt | cut -f2 | sort -u) | sort -u | sort -k2,2 -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; samples = ""} {if(cur != "" && cur != $2){print cur "\t" samples; samples = ""} cur = $2; samples = samples ";" $1} END {print cur "\t" samples}' | sed 's/\t;/\t/g' | sed 's/_/\t/g' | awk '$1 != ""' > $pert/dee2_${species}_sample_controls.txt
#done
#done

#Extract the read counts
#for pert in gene drug; do
#mkdir -p $pert/readcounts $pert/tpm
#mkdir -p $pert/readcounts/archs4 $pert/readcounts/recount3 $pert/readcounts/dee2 $pert/tpm/archs4 $pert/tpm/recount3 $pert/tpm/dee2
#for species in human mouse; do
#mkdir $pert/readcounts/archs4/$species $pert/readcounts/recount3/$species $pert/readcounts/dee2/$species $pert/tpm/archs4/$species $pert/tpm/recount3/$species $pert/tpm/dee2/$species
##ARCHS4
#for sample in $(cat $pert/archs4_${species}_sample_controls.txt | cut -f1,3 | sed 's/\t/\n/g' | sed 's/;/\n/g' | sort -u | comm -23 - <(ls $pert/tpm/archs4/$species/ | cut -d. -f1 | sort -u)); do
#index=$(cat ../corpora/archs4/${species}_sample_list.txt | grep -wn $sample | cut -d: -f1 | head); echo $sample $index;
#python3 ../src/archs4_sample_readcounts.py ../corpora/archs4/${species}_gene_v2.5.h5 $index | awk '{print NR "\t" $0}' | sort -k1,1 | join -t$'\t' <(cat ../corpora/archs4/${species}_gene_list.txt | awk '{print NR "\t" $0}' | sort -k1,1) - | cut -f2- | awk '$2 != 0' > $pert/readcounts/archs4/$species/$sample.txt
#done
##Recount3
#for srr in $(cat $pert/recount3_${species}_sample_controls.txt | cut -f1,3 | sed 's/;/\n/g' | sed 's/\t/\n/g' | sort -u | comm -23 - <(ls $pert/tpm/recount3/$species/ | cut -d. -f1 | sort -u)); do 
#study=$(cat ../corpora/recount3/${species}_srp_to_srr.txt | awk '$2 == "'$srr'"' | cut -f1 | sort -u | head -1)
#index=$(zcat ../corpora/recount3/${species}_studies/sra.gene_sums.$study.*.gz | grep -v '#' | head -1 | sed 's/\t/\n/g' | grep -wn $srr | cut -d: -f1)
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 0.1; done
#zcat ../corpora/recount3/${species}_studies/sra.gene_sums.$study.*.gz | grep ENS | cut -f1,$index | awk '$2 > 0' > $pert/readcounts/recount3/$species/$srr.txt &
#done
##DEE2
#for srr in $(cat $pert/dee2_${species}_sample_controls.txt | cut -f1,3 | sed 's/;/\n/g' | sed 's/\t/\n/g' | sort -u | comm -23 - <(ls $pert/tpm/dee2/$species/ | cut -d. -f1 | sort -u)); do
#suffix=$(echo $srr | rev | cut -b-3 | rev)
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 5 ]; do jobs; sleep 1; done
#zcat ../corpora/dee2/${species}_chewed_3/$suffix.txt.gz | awk '$1 == "'$srr'"' | cut -f2- | awk '$2 > 0' > $pert/readcounts/dee2/$species/$srr.txt &
#done
#done
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done
#done

##Convert those read counts to transcripts per million
#for pert in gene drug; do
#for db in $(ls $pert/readcounts); do
#for species in human mouse; do
#for file in $(ls $pert/readcounts/$db/$species | sort -u | comm -23 - <(ls $pert/tpm/$db/$species/ | sort -u)); do
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 0.1; done
#cat $pert/readcounts/$db/$species/$file | awk 'BEGIN {FS = "\t"; t = 0} {t += $2; print} END {print "total\t" t}' | sort -k1,1r | awk 'BEGIN {FS = "\t"} {if(NR == 1) {total = $2} else{print $1 "\t" $2 * 1000000 / total}}' > $pert/tpm/$db/$species/$file &
#done
#done
#done
#done
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 0.1; done

#Calculate expression z-scores of each perturbed sample relative to its controls
#for pert in gene drug; do
#mkdir -p $pert/sample_z
#for db in archs4 recount3 dee2; do
#mkdir -p $pert/sample_z/$db
#for species in human mouse; do
#mkdir -p $pert/sample_z/$db/$species
#bash ../src/sample_z.sh $pert/sample_z/$db/$species $pert/tpm/$db/$species $pert/${db}_${species}_sample_controls.txt
#done
#done
#done

#Aggregate all of the samples with the same gene perturbed and calculate overall signatures
#for pert in gene drug; do
#rm -rf $pert/average_z $pert/stdev_z $pert/nested_z $pert/f1_matches $pert/f1_predictions
#mkdir -p $pert/average_z $pert/stdev_z $pert/nested_z
#for species in human mouse; do
#speciesid=9606
#if [ $(echo $species | grep mouse | wc -l) -gt 0 ]; then speciesid=10090; fi
#mkdir $pert/average_z/$species $pert/stdev_z/$species $pert/nested_z/$species
#for targ in $(cat $pert/*_${species}_sample_controls.txt | cut -f2 | sort -u); do
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 0.1; done
#(
#(
#for sample in $(cat $pert/archs4_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/archs4/$species/zscores/${sample}_${targ}.txt; done;
#for sample in $(cat $pert/recount3_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/recount3/$species/zscores/${sample}_${targ}.txt | awk 'BEGIN {FS = "\t"} {gsub("\\..*", "", $1); print $1 "\t" $2}'; done
#for sample in $(cat $pert/dee2_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/dee2/$species/zscores/${sample}_${targ}.txt | awk 'BEGIN {FS = "\t"} {gsub("\\..*", "", $1); print $1 "\t" $2}' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(zcat ../corpora/entrez/gene2ensembl.gz | awk '$1 == '$speciesid | cut -f3,5 | awk 'BEGIN {FS = "\t"} $2 != "-" {gsub("\\..*", "", $2); print $1 "\t" $2}' | sort -k2,2) - | cut -f2-; done
#) | sort -k1,1 | awk 'BEGIN {FS = "\t"; gene=""; t = 0; n = 0} {if(gene != $1 && gene != ""){print gene "\t" t / n; t = 0; n = 0} gene = $1; t += $2; n += 1} END {if(gene != ""){print gene "\t" t / n}}' > $pert/average_z/$species/$targ.txt
#(
#for sample in $(cat $pert/archs4_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/archs4/$species/zscores/${sample}_${targ}.txt | sort -k1,1 | join -t$'\t' - <(cat $pert/average_z/$species/$targ.txt | sort -k1,1) | awk '{print $1 "\t" ($2 - $3)^2}'; done;
#for sample in $(cat $pert/recount3_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/recount3/$species/zscores/${sample}_${targ}.txt | awk 'BEGIN {FS = "\t"} {gsub("\\..*", "", $1); print $1 "\t" $2}' | sort -k1,1 | join -t$'\t' - <(cat $pert/average_z/$species/$targ.txt | sort -k1,1) | awk '{print $1 "\t" ($2 - $3)^2}'; done
#for sample in $(cat $pert/dee2_${species}_sample_controls.txt | awk '$2 == "'$targ'"' | cut -f1 | sort -u); do cat $pert/sample_z/dee2/$species/zscores/${sample}_${targ}.txt | awk 'BEGIN {FS = "\t"} {gsub("\\..*", "", $1); print $1 "\t" $2}' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(zcat ../corpora/entrez/gene2ensembl.gz | awk '$1 == '$speciesid | cut -f3,5 | awk 'BEGIN {FS = "\t"} $2 != "-" {gsub("\\..*", "", $2); print $1 "\t" $2}' | sort -k2,2) - | cut -f2- | sort -k1,1 | join -t$'\t' - <(cat $pert/average_z/$species/$targ.txt | sort -k1,1) | awk '{print $1 "\t" ($2 - $3)^2}'; done
#) | sort -k1,1 | awk 'BEGIN {FS = "\t"; gene=""; t = 0; n = 0} {if(gene != $1 && gene != ""){print gene "\t" sqrt(t / n); t = 0; n = 0} gene = $1; t += $2; n += 1} END {if(gene != ""){print gene "\t" sqrt(t / n)}}' > $pert/stdev_z/$species/$targ.txt
#cat $pert/average_z/$species/$targ.txt | sort -k1,1 | join -t$'\t' - <(cat $pert/stdev_z/$species/$targ.txt | sort -k1,1) | awk 'BEGIN {FS = "\t"} {if($1 == 0 || $3 == 0) {print $1 "\t0"} else{print $1 "\t" $2 / $3}}' | awk '$2 != 0' > $pert/nested_z/$species/$targ.txt
#rm $pert/average_z/$species/$targ.txt $pert/stdev_z/$species/$targ.txt) &
#done
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done
#rm $(wc -l $pert/nested_z/$species/* | awk '$1 == 0 {print $2}')
#done
#done

#Match signatures and predict regulatory relationships
#for pert in gene drug; do
#mkdir -p $pert/f1_matches $pert/f1_predictions
#for species in human mouse; do
#mkdir -p $pert/f1_matches/$species $pert/f1_predictions/$species
#bash ../src/match_signatures.sh $pert/nested_z/$species/ gene/nested_z/$species $pert/f1_matches/$species &
#done
#done
#while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done

for pert in gene drug; do
for species in human mouse; do
bash ../src/indirect_predictions.sh $pert/f1_matches/$species ../corpora/archs4/${species}_column_gene_entrez.txt ../corpora/archs4/${species}_correlation_table.txt $pert/f1_predictions/$species &
done
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done

#Get output statistics for the manuscript
#Count the samples in each database
mkdir output_stats
(echo $'Database\tSpecies\tTotal samples\tGene-disrupted samples\tDrug-treated samples'
for db in archs4 recount3 dee2; do
for species in human mouse; do
(echo $db | tr '[:lower:]' '[:upper:]'
echo $species | tr '[:lower:]' '[:upper:]'
cat gene/${db}_${species}_sample_controls.txt drug/${db}_${species}_sample_controls.txt | cut -f1,3 | sed 's/\t/\n/g' | sed 's/;/\n/g' | awk '$1 != ""' | sort -u | wc -l
cat gene/${db}_${species}_sample_controls.txt | cut -f1 | sort -u | wc -l
cat drug/${db}_${species}_sample_controls.txt | cut -f1 | sort -u | wc -l
) | paste -sd$'\t'
done
done
) > output_stats/sample_counts.txt


