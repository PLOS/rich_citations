//= require jquery

fixture.preload("journal.pone.0067380.html");

module("rich citations javascript", {
  setup: function() {
    this.fixtures = fixture.load("journal.pone.0067380.html", true);
  }
});

test("jquery quote id", function() {
    equal(jq("hello.world"), "#hello\\.world");
    equal(jq("hello:world"), "#hello\\:world");
    equal(jq("hello_world"), "#hello_world");
});

test("loads fixtures", function() {
  ok(document.getElementById("references").tagName === "A", "is in the dom");
});

test("arraySorter", function () {
    equal(0, arraySorter({sort: ["a"]}, {sort: ["a"]}));
    equal(-1, arraySorter({sort: ["a"]}, {sort: ["b"]}));
    equal(0, arraySorter({sort: ["a", 1]}, {sort: ["a", 1]}));
    equal(-1, arraySorter({sort: ["a", 1]}, {sort: ["a", 2]}));
    equal(1, arraySorter({sort: ["a", 1]}, {sort: ["a", 0]}));
    var alpha = {sort: ["a", 0, 2, 3]};
    var beta =  {sort: ["a", 1, 1, 1]};
    equal([beta, alpha].sort(arraySorter)[0], alpha);
});

test("mkSortString", function () {
    strictEqual(mkSortString("Hello, world"), "hello world");
    strictEqual(mkSortString("the standard hello world of computing"), "standard hello world of computing");
});

test("mkSortField", function () {
    var ref =  {
      "sections": {
        "Discussion": 1
      },
      "doi": "10.1098\/rsif.2007.1189",
      "info": {
        "authors": [
          {
            "fullname": "D. Lowry"
          },
          {
            "fullname": "P. J Motta"
          }
        ],
        "first_author": {
          "last_name": "Lowry",
          "first_name": "D."
        },
        "end_page": "652",
        "start_page": "641",
        "issue": "23",
        "volume": "5",
        "year": "2008",
        "journal": "Journal of The Royal Society Interface",
        "title": "Relative importance of growth and behaviour to elasmobranch suction-feeding performance over early ontogeny",
        "score": 4.2480526,
        "doi": "10.1098\/rsif.2007.1189",
        "source": "crossref"
      },
      "mentions": 1,
      "median_co_citations": 2.0,
      "citation_groups": [
        {
          "word_position": 6487,
          "section": "Discussion",
          "context": "\u2026thresher shark's body that are sequentially involved in the tail-slapping process increase in size and length throughout a shark's ontogeny [53]\u2013[55]. Larger sharks with longer tails are likely to require\u2026",
          "references": [
            "pone.0067380-Mollet1",
            "pone.0067380-LinghamSoliar1",
            "pone.0067380-Lowry1"
          ],
          "count": 3
        }
      ],
      "index": 55,
      "id": "pone.0067380-Lowry1"
    };
    var refNoInfo = { mentions: 10, index: 1, citation_groups: [ { word_position: 83 }] };
    strictEqual("relative importance of growth and behaviour to elasmobranch suction-feeding performance over early ontogeny", mkSortField(ref, "title"));
    strictEqual(1, mkSortField(ref, "mentions"));
    strictEqual(6487, mkSortField(ref, "appearance"));
    strictEqual("lowry d", mkSortField(ref, "author"));
    strictEqual("2008", mkSortField(ref, "year"));
    strictEqual(55, mkSortField(ref, "index"));
    strictEqual("journal of royal society interface", mkSortField(ref, "journal"));

    /* reference with no info */
    strictEqual(null, mkSortField(refNoInfo, "author"));
    strictEqual(null, mkSortField(refNoInfo, "year"));
    strictEqual(null, mkSortField(refNoInfo, "title"));
    strictEqual(null, mkSortField(refNoInfo, "journal"));
    
    /* anything else should return null */
    strictEqual(null, mkSortField(ref, "foobar"));
});
