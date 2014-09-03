# Rich Citations API draft

## Terminology
- *paper*: a citable object with an identifier
- *reference*: a reference from paper A to paper B with metadata
- *citation*: a string in a paper which refers to a reference, e.g. `[1]`
- *citation group*: a group of citations in a paper, e.g. `[1], [8]`
- *reference metadata*: metadata about a reference in an article,
    e.g., its context
- *bibliographic metadata*: bibliographic metadata about an article as returned by
    CrossRef, etc.
- *metadata*: both bibliographic and reference metadata
    
(I think this terminology is consistent with what we have used
before.)

## Use cases
- users can download the metadata about a given article A
    - possible: users can chose how much metadata to include, e.g. can
        then select whether or not to include bibliographic metadata
        about articles referenced in A
- users can upload reference metadata for an article
    - question: who is authorized to upload metadata about a given
        paper’s articles?
    - this automatically fetches relevant *bibliographic metadata*
        from CrossRef and other sources
        - question: should users need to specify identifiers to fetch
            bibliographic metadata, or can they upload citation text
            and have it discovered via CrossRef?
- possible: users can upload bibliographic metadata for an article
    - CrossRef is planning to develop a correction overlay, so that
        people other than publisher can correct metadata, while
        CrossRef retains the original metadata
- fetching metadata about a PLOS article should generate the metadata
    on the fly
    - perhaps this should be completely prepopulated?
- possible: users should be able to partially update an item, e.g. add
    a missing field
- users can upload reference metadata for an article and have the
    bibliographic metadata provided automatically via CrossRef
- possible: users can download reference metadata about a *referenced* article;
    that is, they can download all known references to a given
    article. This reverses the usual case.
- possible: users can upload partial reference metadata about an
    article, e.g., it can indicate A cites B *without* including
    reference context

## Identifier formats

- URIs should be used for all identifiers; this means that we do not
    external information to distinguish between a a DOI and an ISBN.
    Examples:
    - DOI: `http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1`
    - ISBN: `urn:isbn:0-486-27557-4`
    - Pubmed: `http://identifiers.org/pubmed/16381840`
    - PMC: `http://identifiers.org/pmc/PMC3531190`
    - arxiv ID: `http://arxiv.org/abs/1407.4120`
    - NIHMS ID: ?
    - github repo name/commit id:
        - `http://github.com/foo/bar`
        - `http://github.com/foo/bar/commit/f6f5500ac3d25ea379bc0e326ef69e05de11714f`
    - URL + Date: ?
    - URL: `http://example.org/`

## Getting the reference information for an article
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
    "text": "Doe J. (2000) Morbi vitae lorem blandit. Duis in lorem interdum. 14: 11–18.",
    "bibliographic": { … },
    "citation_groups": [ … ]
}
```

We distinguish between a paper and a reference. A paper is identified
by a URI, e.g. `http://dx.doi.org/10.1234/1`. A reference is identified by a
different URI. For PLOS papers this is the citing paper with an anchor
link, e.g.: `http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Doe1`.
In the reference metadata the `id` field identifies the reference,
while `citing_id` identifies the *citing* paper and the `cited_id`
fields identifies the *cited* paper.

## Updating

It is possible to upload information about the references in an
article to Rich Citations. In order to add information about a paper,
simply `PUT` the data to the corresponding 

## Bibliographic metadata

We use
[citeproc-json](https://github.com/citation-style-language/schema/blob/master/csl-data.json)
as our format for bibliographic metadata, stored in the
`bibliographic` fields above.

 bIn addition to the fields defined in the above document, we also
include information about the item’s license in a `license` field.
This field is a hash with a `url` field that links to information
about the license.

```
{
    "url": "http://creativecommons.org/licenses/by/3.0/"
}
```

## Citation groups

A *citation group* describes a group of citations in a paper and is 
 of the form:

```
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
}
```

Each paper containing reference metadata will have an array of
citation groups in the `citation_groups` field.

## Delayed processing of 
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
            "text": "Doe J. (2000) Morbi vitae lorem blandit. Duis in lorem interdum. 14: 11–18.",
            "bibliographic": { … },
            "citation_groups": [ (see below) ],
        },
        "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Roe1": {
            "id": "http://dx.doi.org/10.1371/journal.pone.0000000#pone.0000000-Roe1",
            "citing_id": "http://dx.doi.org/10.1371/journal.pone.0000000",
            "cited_id": "http://dx.doi.org/10.1234/1",
            "index": 1,
            "self_citation": false,
            "text": "Roe J. (2000) Maecenas imperdiet leo ut bibendum auctor. Vivamus mollis. 88: 1012–22.",
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

To retrieve only information about a single reference
:
```
GET http://api.richcitations.org/v0/reference?id=http%3A%2F%2Fdx.doi.org%2F10.1371%2Fjournal.pone.0000000%23pone.0000000-Doe1
…
```

## Biliographic metadata download

Allow users to download references. This is mostly a passthrough
directly to crossref for RIS, etc. We cache the metadata. We can also
provide citeproc-json metadata about non-crossref items.

- `GET http://api.richcitations.org/v0/paper?id=http%3A%2F%2Fdx.doi.org%2F10.1234%2F1`
  returns citeproc-json formatted metadata
- `GET http://api.richcitations.org/v0/paper?id=http%3A%2F%2Fdx.doi.org%2F10.1234%2F1&format=ris`
  returns RIS formatted bibliographic metadata
- `GET http://api.richcitations.org/v0/paper?id=http%3A%2F%2Fdx.doi.org%2F10.1234%2F1&format=bibtex`
  returns BibTeX formatted bibliographic metadata

## Issues

- Conflicting bibliographic metadata: if 2 users upload conflicting
    bibliographic metadata about the same item, how do we reconcile?
    We are currently storing bibliographic metadata only once for each
    item.
- Should write-API users be allowed to skip uploading bibliographic
    metadata?
