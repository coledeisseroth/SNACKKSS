import sys
import os
from collections import defaultdict
import numpy as np
import h5py

h5_file = h5py.File(sys.argv[1], 'r')

index = int(sys.argv[2]) - 1

readcounts = list(h5_file['data']['expression'][:,index])

for i in range(len(readcounts)): print(readcounts[i])

