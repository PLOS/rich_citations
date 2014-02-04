#!/usr/bin/env python
#
# Code written by Adam Becker
# abecker@plos.org


"""
citation_script.py

Created by Adam M Becker on 2014-01-04.
"""

from citation_utilities import *
import pickle

SEARCH_SUBJECT = "circadian rhythms"
DATABASE_FILE = "circadian_database.pickle"
MAX_PAPERS = 500

# Find information about a bunch of PLOS papers!
search_results = plos_search(SEARCH_SUBJECT, query_type = "subject", rows = MAX_PAPERS)
print "Retrieving " + str(len(search_results)) + " papers from PLOS journals..."
# Get their dois!
dois = plos_dois(search_results)
# Get the papers!
papers = [remote_soupify(doi) for doi in dois]
# Use them to build a database of papers that they cite, with aggregated citation metadata!
database = citation_database(papers)

# Save the database for later use.
print "Saving the database!"
f = open(DATABASE_FILE, "w")
pickle.dump(database, f)
f.close()