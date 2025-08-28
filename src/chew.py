#This script is designed to crunch a body of text into bite-sized pieces that a BERT model can read. The hard maximum is 512, so this script gives a safe buffer and allows no more than 500.

import sys
import os

max_tokens = 500
if "-t" in sys.argv:
    max_tokens = int(sys.argv[sys.argv.index("-t")+1])
    del sys.argv[sys.argv.index("-t")+1]
    del sys.argv[sys.argv.index("-t")]

ckpt = sys.argv[2]

from transformers import AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained(ckpt, add_prefix_space=True)

def chew_tokens(sentence):
    words = sentence.split(' ')
    tokenized_input = tokenizer(words, is_split_into_words=True)
    if len(tokenized_input["input_ids"]) <= max_tokens: return [sentence]
    segments = []
    if(len(words) < 2):
        halfway = int(len(sentence) / 2)
        half1 = sentence[:halfway]
        half2 = sentence[halfway:]
    else:
        halfway = int(len(words) / 2)
        half1 = ' '.join(words[:halfway]) + ' '
        half2 = ' '.join(words[halfway:])
    segments += chew_tokens(half1)
    segments += chew_tokens(half2)
    return segments

for line in open(sys.argv[1]):
    line = line.strip().split("\t")
    try: segments = chew_tokens(line[1])
    except IndexError: continue
    except RecursionError: continue
    for i in range(len(segments)):
        print(line[0] + "\t" + str(i) + "\t" + segments[i])



