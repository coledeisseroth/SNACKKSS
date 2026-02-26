for pert in gene drug; do
mkdir -p $pert
touch $pert/study_info_chewed.txt $pert/predictions.txt
python3 ../src/chew.py <(for species in human mouse; do cat ../metadata/$species/study_info.txt | sort -k1,1 | join -t$'\t' - <(cat ../metadata/$species/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../metadata/$species/sample_info.txt | cut -f-2 | sort -k2,2) | cut -f2 | uniq | sort -u) | join -t$'\t' - <(cat ../metadata/$species/study_info.txt | cut -f1 | sort -u | comm -23 - <(cat $pert/predictions.txt | cut -f1 | cut -d_ -f1 | sort -u)); done | sort -u) ../models/${pert}_study_model | cut -f1,3 > $pert/study_info_chewed_new.txt
python3 ../src/text_classification_predict.py ../models/${pert}_study_model $pert/study_info_chewed_new.txt > $pert/predictions_new.txt
cat $pert/study_info_chewed_new.txt $pert/study_info_chewed.txt | sort -u > tmp; mv tmp $pert/study_info_chewed.txt
cat $pert/predictions.txt $pert/predictions_new.txt | sort -u > tmp; mv tmp $pert/predictions.txt
done

