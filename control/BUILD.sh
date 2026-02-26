#Get the pairs of samples where one has exactly one less perturbation than the other
for pert in gene drug; do
mkdir -p $pert
mkdir -p $pert/minusone
targetfile=targets_wide.txt
if [ $(echo $pert | grep drug | wc -l) -gt 0 ]; then targetfile=targets_nodmso.txt; fi
cat ../metadata/*/sample_info.txt | cut -f-2 | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../target/$pert/$targetfile | cut -f1 | sort -u) | cut -f2 | sort -u | join -t$'\t' - <(cat ../metadata/*/sample_info.txt | cut -f-2 | sort -k1,1) | sort -u > $pert/shortened_study_samples.txt
for gse in $(cat ../target/$pert/$targetfile | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat $pert/shortened_study_samples.txt | cut -f-2 | sort -k2,2) | cut -f2 | sort -u); do
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 10 ]; do jobs; sleep 1; done
cat $pert/shortened_study_samples.txt | awk '$1 == "'$gse'"' | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../target/$pert/$targetfile | sort -k1,1) | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat $pert/shortened_study_samples.txt | awk '$1 == "'$gse'"' | sort -k2,2 | join -t$'\t' -1 2 -2 1 -a 1 -o auto -e '.' - <(cat ../target/$pert/$targetfile | sort -k1,1) | sort -k2,2) | awk 'BEGIN {FS = "\t"} $2 != $4 && $3 != $5 {if($5 == "."){if(index($3, ";") == 0){print "#" $2 "\t" $4} next} x = $5; gsub(";", "\t", x); print $1 "\t" $2 "\t" $4 "\t;" $3 ";\t" x}' | awk 'BEGIN {FS = "\t"} {if(substr($0, 0, 1) == "#"){print; next} for(i=5; i <= NF; i++){if(index($4, ";" $i ";") == 0){next} else{gsub(";" $i ";", ";", $4)}} if($4 != ";" && index(substr($4, 2, length($4) - 2), ";") == 0){print $2 "\t" $3}}' | sed 's/#//g' > $pert/minusone/$gse.txt &
done
while [ $(jobs | grep 'Running\|Done' | wc -l) -gt 0 ]; do jobs; sleep 1; done
cat $pert/minusone/* > $pert/minusone_pairs.txt
rm -r $pert/minusone
cat ../metadata/*/sample_info.txt | cut -f-2 | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat $pert/minusone_pairs.txt | cut -f1 | uniq | sort -u) | cut -f2 | sort -u | join -t$'\t' - <(cat ../metadata/*/sample_info.txt | sort -k1,1) | sort -u > $pert/shortened_sample_info.txt
done

#Only look at studies with a non-exorbitant number of comparisons (<10000) to do:
for pert in gene drug; do
cat $pert/minusone_pairs.txt | cut -f1 | uniq -c | awk '{print $2 "\t" $1}' | sort -k1,1 | join -t$'\t' -1 1 -2 2 - <(cat $pert/shortened_study_samples.txt | sort -k2,2) | sort -k3,3 | awk 'BEGIN {FS = "\t"; cur = ""; samples = ""; count = 0} {if(cur != "" && cur != $3){print cur "\t" count "\t" samples; count = 0; samples = ""} cur = $3; count += $2; samples = samples ";" $1} END {print cur "\t" count "\t" samples}' | sed 's/\t;/\t/g' | awk '$2 < 10000' | cut -f3 | sed 's/;/\n/g' | sort -u > $pert/acceptable_samples.txt
done

#Run the alignment--also, remove anything that has either control-prohibitive differences, or more differing fields than you've ever seen for an experiment/control pair. This cap is eight.
for pert in gene drug; do
mkdir -p $pert/alignments
for split in $(seq 1000 1999 | cut -b2-); do
max_items=8
while [ $(jobs | grep Running | wc -l) -gt 10 ]; do jobs; sleep 1; done
python3 ../src/align_sample_descriptions.py <(cat $pert/minusone_pairs.txt | grep $split$'\t' | sort -u | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat $pert/acceptable_samples.txt) | join -t$'\t' - <(cat $pert/shortened_sample_info.txt | cut -f2- | grep $split$'\t' | sort -t$'\t' -k1,1) | sort -t$'\t' -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat $pert/shortened_sample_info.txt | cut -f2- | sort -t$'\t' -k1,1) | sort -k1,1 -k2,2 -u | awk 'BEGIN {FS = "\t"}{print ".\t" $2 "\t" $3 "\t" $1 "\t" $4}') | cut -f2,4,6 | awk 'BEGIN {FS = "; "} NF <= '$max_items | grep -vif <(cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | awk 'BEGIN {FS = "\t"} NR > 1' | cut -f8 | grep -vf ../corpora/lexica/${pert}_control_prohibitive_exceptions.txt | sed 's/\t/\n/g' | sed 's/;/\n/g' | awk '$1 != ""' | sort -u) > $pert/alignments/$split.txt &
done
done
while [ $(jobs | grep Running | wc -l) -gt 0 ]; do jobs; sleep 1; done

#Chew the descriptions, and don't consider the ones with more than 500 tokens
for pert in gene drug; do
mkdir -p $pert/alignments_chewed
for split in $(ls $pert/alignments); do
python3 ../src/chew.py <(cat $pert/alignments/$split | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3}') ../models/${pert}_control_model | awk 'BEGIN {FS = "\t"} $2 == 0' | cut -f1,3 > $pert/alignments_chewed/$split
done
done

#Run the classification. This step is designed for seamless updating, and ensures that you only have to classify each pair once.
for pert in gene drug; do
mkdir -p $pert/predictions
for split in $(ls $pert/alignments_chewed); do
touch $pert/predictions/$split
done
mkdir -p $pert/predictions_new
for split in $(ls $pert/predictions); do
if [ $(comm -3 <(cat $pert/predictions/$split | cut -f1 | sort -u) <(cat $pert/alignments_chewed/$split | cut -f1 | sort -u) | wc -l) -eq 0 ]; then continue; fi
python3 ../src/text_classification_predict.py ../models/${pert}_control_model <(cat $pert/alignments_chewed/$split | cut -f1 | sort -u | comm -23 - <(cat $pert/predictions/$split | cut -f1 | sort -u) | join -t$'\t' - <(cat $pert/alignments_chewed/$split | sort -k1,1) | sort -u) > $pert/predictions_new/$split
done
for split in $(ls $pert/predictions_new); do
cat $pert/predictions/$split $pert/predictions_new/$split | awk 'BEGIN {FS = "\t"} NF > 4' | sort -u > tmp; mv tmp $pert/predictions/$split
done
done

#Check for any issues
for pert in gene drug; do
wc -l $pert/predictions/* | sed 's/predictions//g' | awk '{print $2 "\t" $1}' | sort -k1,1 | join -t$'\t' - <(wc -l $pert/alignments_chewed/* | sed 's/alignments_chewed//g' | awk '{print $2 "\t" $1}' | sort -k1,1) | awk '$2 != $3 {print "CONTROL PREDICTION ERROR: " $0}'
done

#Turn the control classifications into a wide-format list of controls for each sample
#Note: Because control classification is by far the most expensive part of this procedure, we do not overwrite the classifications from previous iterations--therefore, there will inevitably be several sample pairs that we no longer want to classify. We thus filter the no-longer-applicable sample pairs out when generating the final pipeline output.
for pert in gene drug; do
targetfile=targets_wide.txt
if [ $(echo $pert | grep drug | wc -l) -gt 0 ]; then targetfile=targets_nodmso.txt; fi
for file in $(ls $pert/predictions); do
cat $pert/predictions/$file | awk '$2 == "POSITIVE"' | cut -f1 | sort -u | comm -12 - <(cat $pert/alignments_chewed/$file | cut -f1 | sort -u) | sed 's/_/\t/g' | sort -k1,1 | join -t$'\t' - <(cat ../target/$pert/$targetfile | sort -k1,1) | sort -k2,2 | join -t$'\t' -1 2 -2 1 -a 1 -o auto -e '.' - <(cat ../target/$pert/$targetfile | sort -k1,1) | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $4); print $2 "\t" $1 "\t;" $3 ";\t" $4}' | awk 'BEGIN {FS = "\t"} {for(i = 4; i <= NF; i++){gsub(";" $i ";", ";", $3)} print $1 "\t" $2 "\t" $3 "\t"}' | sed 's/;\t//g' | sed 's/\t;/\t/g' | sort -u | awk 'BEGIN {FS = "\t"} {print $1 "_" $3 "\t" $2}' | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; controls = ""} {if(cur != "" && cur != $1){print cur "\t" controls; controls = ""} cur = $1; controls = controls ";" $2} END {print cur "\t" controls}' | sed 's/\t;/\t/g' | sed 's/_/\t/g' | awk 'BEGIN {FS = "\t"} index($3, ";") > 0'
done > $pert/sample_pert_controls.txt
done

