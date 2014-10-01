# About the Rich Citations API Alpha

Rich Citations is a PLOS Labs project adding metadata to citation data
in scientific articles and stores this information in a centralized
database. This alpha API allows you to access and scrape the Rich
Citations database.

## Terminology
For the definitions below, assume that you are reading a paper A, that contains in-text citations and references to other papers, including paper B.

- *paper*: a citable object with an identifier, usually a scientific article
- *reference*: a reference in paper A to paper B, containing metadata, usually at the end of the paper in the reference section
- *citation*: a string in paper A which refers to paper B, e.g. `[1]`, usually the body of paper A
- *citation group*: a group of citations in a paper, e.g. `[1],[8],[13]` or `[4]-[7]`
- *reference metadata*: metadata about a reference in an article
- *bibliographic metadata*: metadata about an article as returned by
    crossref, etc.

## Identifier formats

- URIs should be used for all identifiers; this means that we do not
    use external information to distinguish between a a DOI and an ISBN.
    Examples:
    - DOI: `http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1`
    - ISBN: `urn:isbn:0-486-27557-4`
    - PubMed: `http://identifiers.org/pubmed/16381840`
    - PubMed Commons (PMC): `http://identifiers.org/pmc/PMC3531190`
    - arxiv ID: `http://arxiv.org/abs/1407.4120`
    - github repo name/commit id:
        - `http://github.com/foo/bar`
        - `http://github.com/foo/bar/commit/f6f5500ac3d25ea379bc0e326ef69e05de11714f`
    - URL: `http://example.org/`

## Getting the reference information for a paper

```
GET http://api.richcitations.org/v0/paper?id=http%3A%2F%2Fdx.doi.org%2F10.1371%2Fjournal.pone.0000000
```

This returns JSON describing the paper and its references:

```
{
    "id": "http://dx.doi.org/10.1371/journal.pone.0000000",
    "word_count": 4567,
    "references": { … },
    "bibliographic": { … },
    "citation_groups": [ … ]
}
```

## References

The `references` part of the JSON is a hash with the key being the
unique identifier for the paper as cited in another paper and the
fields.

```
"http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1": {
    "id": "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1",
    "citing_id": "http://dx.doi.org/10.1371/journal.pone.0000000",
    "cited_id": "http://dx.doi.org/10.1234/1",
    "index": 1,
    "self_citation": false,
    "original_citation": "Doe J. (2000) Morbi vitae lorem blandit. Duis in lorem interdum. 14: 11–18.",
    "bibliographic": { … },
    "citation_groups": [ … ]
}
```

We distinguish between a paper and a reference. A paper is identified
by a URI, e.g. `http://dx.doi.org/10.1371/journal.pone.0000000`. A reference is identified by a
different URI. For PLOS papers this is the citing paper A with an anchor
link, e.g.: `http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1`.
In the reference metadata the `id` field identifies the reference,
while `citing_id` identifies the *citing* paper A and the `cited_id`
fields identifies the *cited* paper B.

## Bibliographic metadata

We use
[citeproc-json](https://github.com/citation-style-language/schema/blob/master/csl-data.json)
as our format for bibliographic metadata, stored in the
`bibliographic` fields above.

In addition to the fields defined in the above document, we also
include information about Paper B's license in a `license` field.
This field is a hash with a `url` field that links to information
about the license.

```
{
    "url": "http://creativecommons.org/licenses/by/3.0/"
}
```

## Citation groups

A *citation group* describes a group of citations in a paper. For PLOS, a citation's URL includes the author last name after a hyphen and is of the form:

```
{
    "references": [
        "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-PLOS1",
        "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-PLOS3"
    ],
    "context": {
        "ellipses_before": true,
        "text_before": "non tempor nisi, sed blandit enim. Nam a tortor sapien",
        "citation": "[1, 2]",
        "text_after": ". Praesent felis lorem, dignissim ac diam quis, bibendum vehicula leo.",
        "ellipses_after": false
    },
    "section": "Introduction",
    "word_position": 23
    }
}
```

Each paper containing reference metadata will have an array of
citation groups in the `citation_groups` field.

## (Mostly) full example
```
GET http://api.richcitations.org/v0/paper?id=http%3A%2F%2Fdx.doi.org%2F10.1371%2Fjournal.pone.0000000

{
    "id": "http://dx.doi.org/10.1371/journal.pone.0000000",
    "word_count": 4567,
    "bibliographic": {
        "source": "CrossRef",
        "type": "journal-article",
        "title": "Quisque congue massa",
        "page": "1-8",
        "reference-count": 2,
        "container-title": "PLOS One",
        "author": [
            {
                "given": "John",
                "family": "Doe"
            }
        ],
        "issued": {
            "date-parts": [
                [
                     2013
                ]
            ]
        }
    },
    "references": {
        "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1": {
            "id": "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1",
            "citing_id": "http://dx.doi.org/10.1371/journal.pone.0000000",
            "cited_id": "http://dx.doi.org/10.1234/1",
            "index": 1,
            "self_citation": false,
            "original_citation": "Doe J. (2000) Morbi vitae lorem blandit. Duis in lorem interdum. 14: 11–18.",
            "bibliographic": { … },
            "citation_groups": [ (see below) ],
        },
        "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Roe1": {
            "id": "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Roe1",
            "citing_id": "http://dx.doi.org/10.1371/journal.pone.0000000",
            "cited_id": "http://dx.doi.org/10.1234/1",
            "index": 1,
            "self_citation": false,
            "original_citation": "Roe J. (2000) Maecenas imperdiet leo ut bibendum auctor. Vivamus mollis. 88: 1012–22.",
            "bibliographic": { … },
            "citation_groups": [ (see below) ],
        }
    },
    "citation_groups": [
        {
            "references": [
                "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1",
                "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Roe1"
            ],
            "context": {
                "ellipses_before": true,
                "text_before": "non tempor nisi, sed blandit enim. Nam a tortor sapien",
                "citation": "[1, 2]",
                "text_after": ". Praesent felis lorem, dignissim ac diam quis, bibendum vehicula leo.",
                "ellipses_after": false
            },
            "section": "Introduction",
            "word_position": 23
        }
    ]
}
```
