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
citation_plot.py

Created by Adam M Becker on 2014-01-04.
"""

from __future__ import division
import pickle
from pylab import *

DATABASE_FILE = "circadian_database.pickle"

# Open the database.
f = open(DATABASE_FILE, "r")
db = pickle.load(f)
f.close()

print "Number of papers in database is " + str(len(db)) + "."

citation_range = (5, 10)
papers_in_range = filter(lambda x: x["citations"] >= citation_range[0] and x["citations"] <= citation_range[1], db.values())
print "Number of papers with at least " + str(citation_range[0]) + " citations and no more than " + str(citation_range[1]) + " citations is " + str(len(papers_in_range)) +"."
mean_mentions = [mean(p["ipms"]) for p in papers_in_range]
bins = linspace(1, 10, 19)
fig = figure()
fig.subplots_adjust(left = 0.09, right = 0.98, bottom = 0.11)
hist(mean_mentions, bins)
xticks(size = 30)
yticks(size = 30)
ylabel(r"Number of cited papers ($n = 431$)", size = 40)
xlabel("Mean mention count within citing papers", size = 40)
title("Labs Prototype Test: Paper Mention Count Histogram", size = 40, va = "top", y = 1.1)
show()
