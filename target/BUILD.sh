exit
#Run the BERT classifiers
for pert in gene drug; do
mkdir -p $pert
touch $pert/predictions.txt
python3 ../src/chew.py <(for species in human mouse; do cat ../metadata/$species/sample_info_protocols.txt | sed 's/$SEMICOLON$/;/g' | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../sample/$pert/predictions.txt | awk '$2 == "POSITIVE"' | cut -f1 | sort -u | comm -23 - <(cat $pert/predictions.txt | cut -f1 | sort -u)) | cut -f1,3; done | sort -u) ../models/${pert}_target_model > $pert/sample_info_chewed.txt
python3 ../src/target_predict.py <(cat $pert/sample_info_chewed.txt | cut -f1,3 | sort -u) ../models/${pert}_target_model > $pert/predictions_new.txt
cat $pert/predictions.txt $pert/predictions_new.txt | sort -u > tmp; mv tmp $pert/predictions.txt
done

#Map the extracted targets to their Entrez and PubChem IDs
for species in human mouse; do
if [ $(echo $species | grep human | wc -l) -gt 0 ]; then taxname="Homo_sapiens"
else taxname="Mus_musculus"; fi
cat gene/predictions.txt | sort -k1,1 | join -t$'\t' - <(cat ../metadata/$species/sample_species.txt | sed 's/ /_/g' | awk '$2 == "'$taxname'"' | cut -f1 | sort -u) | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $2); print $1 "\t" $3 "\t" $2}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){gsub("-", "\t", $i); gsub(":", "\t", $i); print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {gsub("_.*", "", $1); print $1 "\t" substr($5, $2+1, $3 - $2) ":" $4}' | grep ":GENE" | sed 's/:GENE//g' | sort -u | awk 'BEGIN {FS = "\t"} {print tolower($2) "\t" $0}' | sort -t$'\t' -k1,1 | join -t$'\t' -1 1 -2 2 - <(cat ../corpora/entrez/${species}_aliases_tall_clean.txt | sort -t$'\t' -k2,2) | cut -f2-
done > gene/predicted_entity_options.txt
for split in $(ls ../corpora/pubchem/split_100K_clean/); do
python3 ../src/clean_column.py <(cat drug/predictions.txt | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $2); print $1 "\t" $3 "\t" $2}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){gsub("-", "\t", $i); gsub(":", "\t", $i); print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {gsub("_.*", "", $1); print $1 "\t" substr($5, $2+1, $3 - $2) ":" $4}' | grep ":CHEM" | sed 's/:CHEM//g' | sort -u | awk 'BEGIN {FS = "\t"} {print tolower($2) "\t" $0}') 0 | sort -t$'\t' -k1,1 | join -t$'\t' -1 1 -2 2 - <(cat ../corpora/pubchem/split_100K_clean/$split | sort -t$'\t' -k2,2) | cut -f2-
done > drug/predicted_entity_options.txt

#Convert these tall files to wide format
for pert in gene drug; do
python3 ../src/resolve_synonyms.py <(cat $pert/predicted_entity_options.txt | sort -u | sort -k1,1 -k2,2 -k3,3) | sort -u > $pert/predicted_collapsed_entities.txt
cat $pert/predicted_collapsed_entities.txt | cut -f1,3 | sort -u | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; targs = ""} {if(cur != "" && cur != $1){print cur "\t" targs; targs = ""} cur = $1; targs = targs ";" $2} END {print cur "\t" targs}' | sed 's/\t;/\t/g' | sort -u > $pert/targets_wide.txt
done

#DMSO is a common vehicle, so make a version that doesn't consider it.
cat drug/targets_wide.txt | awk 'BEGIN {FS = "\t"}{print $1 "\t;" $2 ";"}' | sed 's/;2665;/;/g' | rev | cut -d';' -f2- | rev | sed 's/\t;/\t/g' | awk 'BEGIN {FS = "\t"} $2 != ""' > drug/targets_nodmso.txt

