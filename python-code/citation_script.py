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
