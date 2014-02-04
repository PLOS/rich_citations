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

SEARCH_SUBJECT = "circadian rhythms"
CORPUS_FILE = "circadian_papers.pickle"
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