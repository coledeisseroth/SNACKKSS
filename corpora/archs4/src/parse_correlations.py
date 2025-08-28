import sys
import pandas
correlations = pandas.read_pickle(sys.argv[1])
df = pandas.DataFrame(correlations)
genes = list(df.keys())
print("#\t" + "\t".join(genes))
for gene1 in genes:
    genestring = gene1
    for gene2 in genes:
        genestring += "\t"
        genestring += str(df[gene1][gene2])
    print(genestring)

