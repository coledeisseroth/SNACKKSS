wget 'http://duffel.rail.bio/recount3/human/data_sources/sra/metadata/sra.recount_project.MD.gz'
mv sra.recount_project.MD.gz human_sra.recount_project.MD.gz
wget 'http://duffel.rail.bio/recount3/mouse/data_sources/sra/metadata/sra.recount_project.MD.gz'
mv sra.recount_project.MD.gz mouse_sra.recount_project.MD.gz

mkdir -p wget_error_logs human_studies mouse_studies
cd human_studies
for study in $(zcat ../human_sra.recount_project.MD.gz | awk 'NR > 1' | cut -f3 | sort -u | comm -23 - <(ls | cut -d. -f3 | sort -u)); do
suffix=$(echo $study | rev | cut -b-2 | rev)
wget http://duffel.rail.bio/recount3/human/data_sources/sra/gene_sums/$suffix/$study/sra.gene_sums.$study.G026.gz 2> ../wget_error_logs/$study.txt
sleep 1
done
cd ..

mkdir mouse_studies
cd mouse_studies
for study in $(zcat ../mouse_sra.recount_project.MD.gz | awk 'NR > 1' | cut -f3 | sort -u | comm -23 - <(ls | cut -d. -f3 | sort -u)); do
suffix=$(echo $study | rev | cut -b-2 | rev)
wget http://duffel.rail.bio/recount3/mouse/data_sources/sra/gene_sums/$suffix/$study/sra.gene_sums.$study.M023.gz > ../wget_error_logs/$study.txt
sleep 1
done
cd ..

for srp in $(ls human_studies/| cut -d. -f3 | sort -u); do
zcat human_studies/sra.gene_sums.$srp.G026.gz | head | grep -v '#' | head -1 | cut -f2- | sed 's/\t/\n/g' | awk '{print "'$srp'\t" $0}'
done > human_srp_to_srr.txt

for srp in $(ls mouse_studies/| cut -d. -f3 | sort -u); do
zcat mouse_studies/sra.gene_sums.$srp.M023.gz | head | grep -v '#' | head -1 | cut -f2- | sed 's/\t/\n/g' | awk '{print "'$srp'\t" $0}'
done > mouse_srp_to_srr.txt

