#Here we curate the metadata from GEO that we will ultimately be parsing through with our NLP tools.
#Note that this script is designed to minimize redundancy and repeat downloads as little as possible and recover anything that was missed by previous runs.
#Naturally, this script will not have replicable output.

#Get the SRA name mapping
wget https://ftp.ncbi.nlm.nih.gov/sra/reports/Metadata/SRA_Run_Members.tab

mkdir human mouse
#Get a big list of studies from GEO
for species in human mouse; do
touch $species/datasets.txt
done
curl 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term="Homo+sapiens"\[Organism\]+AND+"Expression+profiling+by+high+throughput+sequencing"\[Filter\]+AND+gse\[ETYP\]&retmax=500000' | grep '<Id>' | cut -d'>' -f2 | cut -d'<' -f1 > human/datasets_new.txt
curl 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term="Mus+musculus"\[porgn\]+AND+"Expression+profiling+by+high+throughput+sequencing"\[Filter\]+AND+gse\[ETYP\]&retmax=500000' | grep '<Id>' | cut -d'>' -f2 | cut -d'<' -f1 > mouse/datasets_new.txt
for species in human mouse; do
cat $species/datasets.txt $species/datasets_new.txt | sort -u > tmp; mv tmp $species/datasets.txt
done

#Fetch series info. We keep a one-second time lag so as not to overload the NCBI server.
for species in human mouse; do
mkdir $species/datasets
for accession in $(cat $species/datasets.txt | sort -u | comm -23 - <(ls $species/datasets/ | sort -u)); do
curl 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id='$accession > $species/datasets/$accession 
sleep 1
done
done
#Remove any series that threw an error when trying to fetch them. A re-run might recover them.
for species in human mouse; do
for file in $(ls $species/datasets); do
if [ $(cat $species/datasets/$file | grep '<eSummaryResult><ERROR>' | wc -l) -gt 0 ]; then rm $species/datasets/$file; echo 'REMOVED '$file' DUE TO ERROR'; fi
done
done

#The GSE accessions are directly derivable from the dataset IDs. Just remove the initial 2 and the trailing zeroes.
for species in human mouse; do
for file in $(ls $species/datasets); do echo $file | awk '{print $1 "\t" $1}' | cut -b2- | awk '{print "#" $0}' | sed 's/#0*/GSE/g' | awk '{print $2 "\t" $1}'; done > $species/dataset_to_gse.txt
done

#Download the soft files, which have the metadata. Again, we keep a time lag of one second.
for species in human mouse; do
mkdir -p $species/soft_files
cd $species/soft_files
for gse in $(cat ../dataset_to_gse.txt | cut -f2 | sort -u | comm -23 - <(ls | cut -d_ -f1 | sort -u)); do
subfolder=$(echo $gse | awk '{if(length($1) < 7){print "GSEnnn"} else{print substr($1, 0, length($1) - 3) "nnn"}}')
link='https://ftp.ncbi.nlm.nih.gov/geo/series/'$subfolder'/'$gse'/soft/'${gse}'_family.soft.gz'
wget $link
sleep 1
done
cd ../..
done

#Assemble tables of study and sample info
for species in human mouse; do
touch $species/study_info.txt
for file in $(ls $species/soft_files | grep GSE | awk 'BEGIN {FS = "_"} {print $1 "\t" $0}' | sort -k1,1 | join -a 1 -o auto -e 0 - <(cat $species/study_info.txt | cut -f1 | sort -u | awk '{print $1 "\t1"}' | sort -k1,1) | awk '$3 == 0' | cut -f2 | sort -u); do zcat $species/soft_files/$file | sed 's/\r//g' | grep -wf ../corpora/lexica/series_useful_fields.txt | sort -u | cut -d' ' -f3- | paste -sd$'\t' | sed 's/\t/. /g' | sed 's/\.\. /. /g' | awk '{print "'$(echo $file | cut -d_ -f1)'\t" $0}'; done | sed 's/"//g' | sed 's/\\//g' | sort -u > $species/study_info_new.txt
cat $species/study_info.txt $species/study_info_new.txt | sort -u > tmp
mv tmp $species/study_info.txt
touch $species/sample_info.txt
for study in $(ls $species/soft_files/ | cut -d_ -f1 | grep GSE | sort -u | comm -23 - <(cat $species/sample_info.txt | cut -f1 | uniq | sort -u)); do zcat $species/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; cat ../corpora/lexica/sample_useful_fields.txt | grep -v protocol) | sed 's/\^SAMPLE = /. . \^SAMPLE = /g' | cut -d' ' -f3- | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | sort -u > $species/sample_info_new.txt
cat $species/sample_info.txt $species/sample_info_new.txt | sort -u > tmp
mv tmp $species/sample_info.txt
touch $species/sample_info_protocols.txt
for study in $(ls $species/soft_files/ | cut -d_ -f1 | grep GSE | sort -u | comm -23 - <(cat $species/sample_info_protocols.txt | cut -f1 | uniq | sort -u)); do zcat $species/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; cat ../corpora/lexica/sample_useful_fields.txt) | sed 's/\^SAMPLE = /. . \^SAMPLE = /g' | cut -d' ' -f3- | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | sort -u > $species/sample_info_protocols_new.txt
cat $species/sample_info_protocols.txt $species/sample_info_protocols_new.txt | sort -u > tmp
mv tmp $species/sample_info_protocols.txt
touch $species/sample_library_strategy.txt
for study in $(ls $species/soft_files/ | cut -d_ -f1 | grep GSE | sort -u | comm -23 - <(cat $species/sample_library_strategy.txt | cut -f1 | uniq | sort -u)); do zcat $species/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; echo '!Sample_library_strategy') | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | cut -f2,3 | sed 's/!Sample_library_strategy = //g' | sort -u > $species/sample_library_strategy_new.txt
cat $species/sample_library_strategy.txt $species/sample_library_strategy_new.txt | sort -u > tmp
mv tmp $species/sample_library_strategy.txt
touch $species/sample_srx.txt
for study in $(ls $species/soft_files/ | cut -d_ -f1 | grep GSE | sort -u | comm -23 - <(cat $species/sample_srx.txt | cut -f1 | uniq | sort -u)); do zcat $species/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; echo '!Sample_relation = SRA: ') | paste -s | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | cut -f2,3 | sed 's/!Sample_relation = SRA: https:\/\/www.ncbi.nlm.nih.gov\/sra?term=//g' | sort -u > $species/sample_srx_new.txt
cat $species/sample_srx.txt $species/sample_srx_new.txt | sort -u > tmp
mv tmp $species/sample_srx.txt
cat SRA_Run_Members.tab | cut -f1,3,8 | grep -v 'unpublished\|withdrawn\|suppressed' | grep SRR | cut -f1,2 | sort -t$'\t' -k2,2 | join -t$'\t' -1 2 -2 2 <(cat $species/sample_srx.txt | awk '$2 != ""' | grep SRX | sort -t$'\t' -k2,2) - | cut -f2- | sort -u > $species/sample_srr.txt
done

