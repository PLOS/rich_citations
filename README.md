citation_tools
==============

Citation Tools

#citation_database(papers, verbose=True)#
    Given a list of soupified papers in PLOS XML format, assembles a database of the papers those papers cite, 
    collects citation numbers and MICCs for each of those papers,
    and then calculates the median number of intra-paper mentions and median MICCs for each paper in the database.
    Returns a dictionary of these measures, along with bare number of citations, keyed by DOI. 
    Papers without discoverable DOIs are removed from the database.

citation_grouper(paper)
    Don't call this directly -- use one of the dictionary or database functions instead.
    Given a soupified XML paper, returns a list of the 'citation groups' within that paper.
    A citation group is all of the papers that are cited together at a certain point in the paper -- the bare stuff of inline co-citations.
    So, for example, a citation group might simply be [1], or it could be [2]-[10], or even [11], [13]-[17], [21].
    The elements within the returned list are themselves lists of soupified XML elements corresponding to citations and connectives.

doi(number, paper, verbose=True)
    DEPRECATED in favor of doi_batch.
    Given a soupified paper and a citation number, attempts to return the DOI of the reference 
    by searching the text of the reference and doing a CrossRef search if that fails.
    Returns None if no DOI can be found.
    Verbose does what it sounds like.
    NB: The automated CrossRef search has intermittent trouble finding things. 
    Not sure why, but this function definitely fails to find DOIs that are nonetheless in the CrossRef database.

doi_batch(paper, crossref=False)
    Returns all the dois for a whole paper, in one batch.
    Works somewhat like the individual doi function above -- searches for a doi inline, then looks elsewhere if that fails --
    but this function looks at the inline HTML DOIs on the PLOS website for the DOIs by default.
    If crossref=True, it uses CrossRef instead, but it submits all the CrossRef requests at once, 
    so it isn't spamming the CrossRef server the way a long series of individual doi calls would.

group_cleaner(group)
    Don't call this directly -- use one of the dictionary or database functions instead.
    Given a citation group like the ones in the list returned by citation_grouper, 
    returns lists of integers that correspond to citation numbers.
    So XML corresponding to [3], [5]-[7] would be returned as [3, 5, 6, 7].

intra_paper_mentions(number, paper)
    DEPRECATED in favor of ipm_dictionary
    Given a soupified paper and a citation number, returns the number of times that citation number is mentioned in the given paper.

ipm_dictionary(paper)
    Creates a dictionary of the number of intra-paper mentions for each thing cited in the given paper.
    Basically runs intra_paper_mentions on every cited thing within the given paper, then stuffs them in a database.
    MUCH faster than actually doing that, though.

ipm_histogram(paper, details=False)
    Returns a database that is essentially the inverse of what ipm_dictonary spits out:
    now the keys are the number of mentions in the paper, and the values are the number of cited things that are mentioned that many times.
    So d[1] is the number of cited things only mentioned once, etc.
    If details = True, the dictionary will instead return a list of the things with the given number of mentions.

micc(number, paper)
    DEPRECATED in favor of micc_dictionary
    Given a paper and a citation number within that paper, 
    returns the median number of inline co-citations of that citation in that paper.
    PAPER PAPER PAPER CITATION PAPER PAPER

micc_dictionary(paper)
    Analogous to citation_number_dictionary, but for MICCs rather than the number of citations.

micc_histogram(paper, details=False)
    Analogous to citation_histogram, but for MICCs rather than the number of citations.

number(citation)
    A little function that translates XML citations into their citation numbers.

plos_dois(search_results)
    Turns search results from plos_search into a list of DOIs.

plos_paper_doi(paper)
    Given a soupified PLOS XML paper, returns that paper's DOI.

plos_search(query, query_type=None, rows=20, more_parameters=None, fq='doc_type:full AND article_type_facet:"Research Article"', output='json', verbose=False)
    Accesses the PLOS search API.
    query: the text of your query.
    query_type: subject, author, etc.
    rows: maximum number of results to return.
    more_parameters: an optional dictionary; key-value pairs are parameter names and values for the search api.
    fq: determines what kind of results are returned. 
    Set by default to return only full documents that are research articles (almost always what you want).
    output: determines output type. Set to JSON by default, XML is also possible, along with a few others.

remote_soupify(doi)
    Given the DOI of a PLOS paper, downloads the XML and parses it using Beautiful Soup.

soupify(filename)
    Opens the given XML file, parses it using Beautiful Soup, and returns the output.