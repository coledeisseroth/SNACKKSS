import sys
import os
from collections import defaultdict
from Bio import Align

unpaired_positive_delim = "@"
aligner = Align.PairwiseAligner()

def best_alignments(descs1, descs2):
    best1 = [0] * len(descs1)
    best1scores = [0] * len(descs1)
    best2 = [0] * len(descs2)
    best2scores = [0] * len(descs2)
    for i in range(len(descs1)):
        for j in range(i, len(descs2)):
            try: score = aligner.align(descs1[i], descs2[j])[0].score
            except ValueError: continue
            if score > best1scores[i]:
                best1[i] = j
                best1scores[i] = score
            if score > best2scores[j]:
                best2[j] = i
                best2scores[j] = score
    return best1, best2


def align_printout(desc1, desc2):
    if not desc1 or not desc2: return desc1, desc2
    root = ""
    delims = [" = ", ": "]
    for delimiter in delims:
        if delimiter not in desc1: continue
        if delimiter not in desc2: continue
        desc1 = desc1.split(delimiter)
        desc2 = desc2.split(delimiter)
        if desc1[0] == desc2[0]:
            root += desc1[0] + delimiter
            desc1 = desc1[1:]
            desc2 = desc2[1:]
        desc1 = delimiter.join(desc1)
        desc2 = delimiter.join(desc2)
    try: alignments = aligner.align(desc1, desc2)
    except ValueError: return desc1, desc2
    alignment = alignments[0]
    commonalities = alignment.aligned
    newdesc1 = ""
    if len(commonalities[0]) > 0:
        if commonalities[0][0][0] > 0: newdesc1 += desc1[:commonalities[0][0][0]]
    for i in range(1, len(commonalities[0])):
        newdesc1 += desc1[commonalities[0][i-1][1]:commonalities[0][i][0]]
    if len(commonalities[0]) > 0:
        if len(desc1) > commonalities[0][-1][1]: newdesc1 += desc1[commonalities[0][-1][1]:]
    if len(commonalities[0]) == 0: newdesc1 = desc1
    newdesc2 = ""
    if len(commonalities[1]) > 0:
        if commonalities[1][0][0] > 0: newdesc2 += desc2[:commonalities[1][0][0]]
    for i in range(1, len(commonalities[1])):
        newdesc2 += desc2[commonalities[1][i-1][1]:commonalities[1][i][0]]
    if len(commonalities[1]) > 0:
        if len(desc2) > commonalities[1][-1][1]: newdesc2 += desc2[commonalities[1][-1][1]:]
    if len(commonalities[1]) == 0: newdesc2 = desc2
    if ": " in root: root = " = ".join(root.split(" = ")[1:])
    else: root = ""
    return root + newdesc1, root + newdesc2


for line in open(sys.argv[1]):
    line = line.strip().split("\t")
    try:
        study = line[0]
        sample1 = line[1]
        sample2 = line[3]
        if sample1 == sample2: continue
        desc1 = line[2]
        if not desc1: continue
        desc2 = line[4]
        if not desc2: continue
    except IndexError: continue
    descs1 = desc1.split('; ')
    descs2 = desc2.split('; ')
    best1, best2 = best_alignments(descs1, descs2)
    newdescs2 = []
    for i in range(len(descs2)):
        d2 = descs2[i]
        d1 = descs1[best2[i]]
        if d1 == d2: continue
        newdesc1, newdesc2 = align_printout(d1, d2)
        if newdesc2 in newdescs2 or newdesc2 == "": continue
        newdescs2.append(newdesc2)
    outstring = "; ".join(newdescs2)
    if not outstring: outstring = "IDENTICAL"
    print("\t".join(line) + "\t" + outstring)

