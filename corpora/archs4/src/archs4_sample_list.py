import sys
import numpy as np
import h5py

h5_file = h5py.File(sys.argv[1], 'r')

samples = list(h5_file['meta']['samples']['sample'])
for i in range(len(samples)): print(str(samples[i]).split("'")[1])
