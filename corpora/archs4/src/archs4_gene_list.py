import sys
import numpy as np
import h5py

h5_file = h5py.File(sys.argv[1], 'r')

genes = list(h5_file['meta']['genes']['ensembl_gene'])
for i in range(len(genes)): print(str(genes[i]).split("'")[1])

