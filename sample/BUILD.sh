exit
for pert in gene drug; do
mkdir -p $pert
touch $pert/predictions.txt
python3 ../src/chew.py <(for species in human mouse; do cat ../metadata/$species/sample_info.txt | sort -k1,1 | join -t$'\t' - <(cat ../study/$pert/predictions.txt | awk '$2 == "POSITIVE"' | cut -d_ -f1 | sort -u) | cut -f2- | sort -k1,1 | join -t$'\t' - <(cat ../metadata/$species/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u); done | sort -u) ../models/${pert}_sample_model > $pert/sample_info_chewed.txt
python3 ../src/text_classification_predict.py ../models/${pert}_sample_model <(cat $pert/sample_info_chewed.txt | cut -f1 | sort -u | comm -23 - <(cat $pert/predictions.txt | cut -f1 | sort -u) | join -t$'\t' - <(cat $pert/sample_info_chewed.txt | cut -f1,3 | sort -u | sort -k1,1)) > $pert/predictions_new.txt
cat $pert/predictions.txt $pert/predictions_new.txt | sort -u > tmp; mv tmp $pert/predictions.txt
done
