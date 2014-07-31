# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#!/usr/bin/env python
#
# Code written by Adam Becker
# abecker@plos.org


"""
zero_mention_script.py

Created by Adam M Becker on 2014-01-04.
"""

from citation_utilities import plos_search, plos_dois, remote_soupify, remote_retrieve, zero_mentions
from itertools import compress
import pickle
from bs4 import BeautifulSoup

SEARCH_SUBJECT = "circadian rhythms"
CORPUS_FILE = "circadian_database.pickle"
FAILURE_FILE = "failure_database.pickle"
MAX_PAPERS = 500

# # Find information about a bunch of PLOS papers!
# search_results = plos_search(SEARCH_SUBJECT, query_type = "subject", rows = MAX_PAPERS)
# print "Retrieving " + str(len(search_results)) + " papers from PLOS journals..."
# # Get their dois!
# dois = plos_dois(search_results)
# # Get the papers!
# # papers = [remote_soupify(doi) for doi in dois]
# papers = [remote_retrieve(doi) for doi in dois]
# # Save the papers for later use.
# print "Saving the papers!"
# f = open(CORPUS_FILE, "w")
# pickle.dump(papers, f)
# f.close()

print "Loading the papers!"
f = open(CORPUS_FILE)
papers = pickle.load(f)
f.close()

#Soupify the papers!
papers = [BeautifulSoup(p, features = "xml") for p in papers]

# Find the offending papers!
fails = [zero_mentions(p) for p in papers]
fails = compress(fails, fails)
# fails = filter(lambda x:x, [zero_mentions(p) for p in papers])
print fails
print sum([len(z[1]) for z in fails])
print [f[0] for f in fails]

# Save the database for later use.
print "Saving the failures!"
f = open(FAILURE_FILE, "w")
pickle.dump(fails, f)
f.close()
