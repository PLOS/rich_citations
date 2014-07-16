/** @jsx React.DOM */
//= require jquery
//= require react
var paper_doi = "10.12345/09876";

var TestUtils = React.addons.TestUtils;
var testRef = {
      "sections": {
        "Introduction": 1
      },
      "mentions": 1,
      "median_co_citations": 0.0,
      "citation_groups": [
        {
          "word_position": 21,
          "section": "Introduction",
          "context": {
              text_before: "Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. ",
              citation: "[1]",
              text_after: " Venison filet mignon exercitation adipisicing meatloaf veniam. ",
              ellipses_after: "\u2026"
          },
          "references": [
            "pone.0000000-Doe1"
          ],
          "count": 1
        },
      ],
      "info": {
        "author": [
          {
            "given": "J",
            "family": "Doe"
          }
        ],
        "page": "79-95",
        "issued": {
          "date-parts": [
            [
              2007
            ]
          ]
        },
        "volume": "2",
        "title": "The best ever",
        "container-title": "Journal of Silly Studies",
        "container-type": "journal",
        "text": "Doe J ( 2007 ) The best ever. Journal of Silly Studies 2: 79\u201395."
      },
      "index": 1,
      "id": "pone.0000000-Doe1"
    };

var testRefWithDoi = $.extend(true, {}, testRef, {"info": {"id": "10.12345/67890", "id_type": "doi"}});

var spinnerPath = '/assets/spinner.gif';

test("jquery quote id", function() {
    equal(jq("hello.world"), "#hello\\.world");
    equal(jq("hello:world"), "#hello\\:world");
    equal(jq("hello_world"), "#hello_world");
});

test("arraySorter", function () {
    equal(0, arraySorter({sort: ["a"]}, {sort: ["a"]}));
    equal(0, arraySorter({sort: [null]}, {sort: ["a"]}));
    equal(0, arraySorter({sort: ["a"]}, {sort: [null]}));
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
    stop();
    $.getJSON("/papers/10.1371/journal.pone.0067380?format=json").
        done(function (fixture) {
            var ref = fixture.references["pone.0067380-Lowry1"];
            strictEqual(1, mkSortField(ref, "mentions"));
            strictEqual(55, mkSortField(ref, "appearance"));
            strictEqual("lowry d", mkSortField(ref, "author"));
            strictEqual(2008, mkSortField(ref, "year"));
            strictEqual(55, mkSortField(ref, "index"));
            strictEqual("journal of royal society interface", mkSortField(ref, "journal"));

            /* reference with no info */
            var refNoInfo = {id: "pone.0067380-Wahnbaeck1",
                             info: {}};
            strictEqual(null, mkSortField(refNoInfo, "author"));
            strictEqual(null, mkSortField(refNoInfo, "year"));
            strictEqual(null, mkSortField(refNoInfo, "journal"));
            
            /* anything else should return null */
            strictEqual(null, mkSortField(ref, "foobar"));
            start();
        });
});

test("mkSearchResultsFilter", function () {
    stop();
    $.getJSON("/papers/10.1371/journal.pone.0067380?format=json").
        done(function (fixture) {
            var filter = mkSearchResultsFilter(buildIndex(fixture.references), "odontodactylus");
            var results = _.filter(fixture.references, filter);
            strictEqual(results.length, 1);
            strictEqual(results[0].ref_id, "pone.0067380-Patek1");
            start();
        });
});

test("buildIndex", function () {
    stop();
    $.getJSON("/papers/10.1371/journal.pone.0067380?format=json").
        done(function (fixture) {
            var idx = buildIndex(fixture.references);
            var results = idx.search("odontodactylus");
            strictEqual(results.length, 1);
            strictEqual(results[0].ref, "pone.0067380-Patek1");
            start();
        });
});

test("sortReferences", function () {
    stop();
    $.getJSON("/papers/10.1371/journal.pone.0067380?format=json").
        done(function (fixture) {
            _.each([{by: "appearance",
                     first: "pone.0067380-Clua1",
                     last: "pone.0067380-Lowry1",
                     sortableCount: 55,
                     unsortableCount: 0},
                    {by: "repeated",
                     first: "pone.0067380-Clua1",
                     last: "pone.0067380-Heithaus1",
                     sortableCount: 91,
                     unsortableCount: 0}],
                   function (d) {
                       var refs = fixture.references;
                       var results = sortReferences(refs, d.by);
                       strictEqual(results.unsortable.length, d.unsortableCount);
                       strictEqual(results.sorted.length, d.sortableCount);
                       strictEqual(results.sorted[0].data.ref_id, d.first);
                       strictEqual(results.sorted[results.sorted.length-1].data.ref_id, d.last);
                   }.bind(this));
            start();
        });
});

test("guid generator", function() {
    var guid1 = guid();
    var guid2 = guid();
    notEqual(guid1, guid2);

    ok(guid2.match("^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$"));
});

test("extract and generated citation reference ids", function() {
    var id = "pone.0067380-Sperone2";
    strictEqual(extractCitationReferenceInfo("pone.0067380-Sperone2"), null);
    strictEqual(extractCitationReferenceInfo(generateCitationReferenceId(id, 0)).id, id);
    strictEqual(extractCitationReferenceInfo(generateCitationReferenceId(id, 0)).count, 0);
    strictEqual(generateCitationReferenceId("pone.0067380-Sperone2", 0), "ref_" + id + "_0");
});

test("formatAuthorNameInvertedInitials", function() {
    strictEqual(formatAuthorNameInvertedInitials({given: "Jane", family: "Roe"}), "Roe J");
    strictEqual(formatAuthorNameInvertedInitials({given: "Mary Jane", family: "Roe"}), "Roe MJ");
    strictEqual(formatAuthorNameInvertedInitials({given: "Jane", family: "Roe Doe"}), "Roe Doe J");
    strictEqual(formatAuthorNameInvertedInitials({given: "Jane", family: "Roe-Doe"}), "Roe-Doe J");
});

test("ordinalStr", function() {
    strictEqual(ordinalStr(1), "1st");
    strictEqual(ordinalStr(2), "2nd");
    strictEqual(ordinalStr(3), "3rd");
    strictEqual(ordinalStr(1000), "1000th");
    strictEqual(ordinalStr(1011), "1011th");
    strictEqual(ordinalStr(1021), "1021st");
});

test("author list", function() {
    var updateHighlightingCalled = false;
    var a = {given: "Jane", family: "Roe"};
    var b = {given: "Joan", family: "Roe"};
    var c = {given: "John", family: "Doe"};
    var d = {given: "James", family: "Doe"};
    var e = {given: "Jennifer", family: "Roe"};
    /* can't make JSX transform work at the moment */
    var authorList4 = ReferenceAuthorList({authors: [a, b, c, d], updateHighlighting: function(){}});
    var authorList5 = ReferenceAuthorList({authors: [a, b, c, d, e],
                                           updateHighlighting: function(){
                                               updateHighlightingCalled=true;
                                           }});
    TestUtils.renderIntoDocument(authorList4);
    TestUtils.renderIntoDocument(authorList5);
    var span4 = TestUtils.findRenderedDOMComponentWithClass(authorList4, 'reference-authors');
    var span5 = TestUtils.findRenderedDOMComponentWithClass(authorList5, 'reference-authors');
    /* all four names should display */
    strictEqual(span4.getDOMNode().textContent, "Roe J, Roe J, Doe J, Doe J");
    /* 2 refs of 5 should be hidden */
    strictEqual(span5.getDOMNode().textContent, "Roe J, Roe J, Doe J, (and 2 more)");
    /* should expand on click */
    var input = TestUtils.findRenderedDOMComponentWithTag(span5, 'a');
    strictEqual(false, updateHighlightingCalled);
    TestUtils.Simulate.click(input);
    strictEqual(span5.getDOMNode().textContent, "Roe J, Roe J, Doe J, Doe J, Roe J");

    /* ensure that updateHighlighting was called */
    strictEqual(true, updateHighlightingCalled);
});

test("abstract display", function() {
    var abs = ReferenceAbstract({ text: "foo bar baz" });
    TestUtils.renderIntoDocument(abs);
    var div = TestUtils.findRenderedDOMComponentWithTag(abs, "div");
    strictEqual(div.getDOMNode().textContent, "▸ Show abstract");
    var input = TestUtils.findRenderedDOMComponentWithTag(abs, 'button');
    TestUtils.Simulate.click(input);
    strictEqual(div.getDOMNode().textContent, "▾ Show abstractfoo bar baz");
});

test("search bar", function() {
    /* test that updating search text will call function with changed text */
    var text = "";
    var f = function(foo) { text = foo; };
    var sb = SearchBar({ filterText: text, onSearchUpdate: f});
    TestUtils.renderIntoDocument(sb);
    var input = TestUtils.findRenderedDOMComponentWithTag(sb, "input");
    TestUtils.Simulate.change(input, {target : { value: "foo" }});
    strictEqual(text, "foo");
});

test("reference with DOI has link", function() {
    var r = ReferenceCore({reference: testRefWithDoi});
    TestUtils.renderIntoDocument(r);
    var title = TestUtils.findRenderedDOMComponentWithClass(r, "reference-link");
    strictEqual(title.getDOMNode().getAttribute("href"), "/interstitial?from=10.12345%2F09876&to=1");
});

test("reference without DOI has no link", function() {
    var r = ReferenceCore({reference: testRef});
    TestUtils.renderIntoDocument(r);
    throws(
        function() {
            TestUtils.findRenderedDOMComponentWithClass(r, "reference-link");
        });
});

test("full reference", function() {
    var r = Reference({reference: testRefWithDoi});
    TestUtils.renderIntoDocument(r);
    equal(r.getDOMNode().textContent, "Doe J (2007)The best everJournal of Silly Studiesdoi: 10.12345/67890Download reference (BibTeX) (RIS)▸ 1 appearance in this article.");
});

test("withReferenceData", function() {
    stop();
    withReferenceData("10.1371/journal.pone.0097164", function (data) {
        strictEqual(data.references["pone.0097164-Ptz7"].info.author[0].family, "Pütz");
        start();
    });
});

test("CrossmarkBadge", function() {
    var r = CrossmarkBadge({reference: {info: {}, updated_by: [{"type": "retraction"}]}});
    TestUtils.renderIntoDocument(r);
    strictEqual(r.getDOMNode().textContent, "RETRACTED");

    var u = CrossmarkBadge({reference: {info: {}, updated_by: [{"type": "updated"}]}});
    TestUtils.renderIntoDocument(u);
    strictEqual(u.getDOMNode().textContent, "UPDATED");

    var n = CrossmarkBadge({reference: {info: {}}});
    TestUtils.renderIntoDocument(n);
    strictEqual(n.getDOMNode().textContent, "");
});

test("ReferenceAppearanceListRevealable with 1 mention in reference list", function() {
    var l = ReferenceAppearanceListRevealable({ reference: testRef });
    var x = TestUtils.renderIntoDocument(l);
    strictEqual(x.getDOMNode().textContent, "▸ 1 appearance in this article.");
});

test("ReferenceAppearanceListRevealable with 1 mention in popover", function() {
    var l = ReferenceAppearanceListRevealable({ reference: testRef, currentMention: 0 });
    var x = TestUtils.renderIntoDocument(l);
    strictEqual(x.getDOMNode().textContent, "Appears once in this article.");
});

test("ReferenceAppearanceList", function() {
    var l = ReferenceAppearanceList({ reference: testRef, currentMention: 0 });
    var x = TestUtils.renderIntoDocument(l);
    strictEqual(x.getDOMNode().textContent, "Introduction▸Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. [1] Venison filet mignon exercitation adipisicing meatloaf veniam. …");
});

test("Revealable", function() {
    var r = Revealable({revealText: "foo", children: ["baz"]});
    TestUtils.renderIntoDocument(r);
    strictEqual(r.getDOMNode().textContent, "▸ foo");
    var input = TestUtils.findRenderedDOMComponentWithTag(r, 'button');
    TestUtils.Simulate.click(input);
    strictEqual(r.getDOMNode().textContent, "▾ foobaz");
});

test("Maybe", function() {
    var t = Maybe({test: true, children: ["foo"]});
    TestUtils.renderIntoDocument(t);
    strictEqual(t.getDOMNode().textContent, "foo");

    var f = Maybe({test: false, children: ["foo"]});
    TestUtils.renderIntoDocument(f);
    strictEqual(f.getDOMNode().textContent, "");
});

var groups = [
    {"count": 1,
     "references": [
        "pone.0000000-Doe1"
     ],
     "section": "Introduction",
     "context": {
         text_before: "Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. ",
         citation: "[1]",
         text_after: " Venison filet mignon exercitation adipisicing meatloaf veniam. ",
         ellipses_after: "\u2026"
     },
     "word_position": 50
    },
    {"count": 2,
     "references": [
         "pone.0000000-Doe1",
         "pone.0000000-Doe2"
     ],
     "section": "Introduction",
     "context": {
         text_before: "Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. ",
         citation: "[1], [2]",
         text_after: " Venison filet mignon exercitation adipisicing meatloaf veniam. ",
         ellipses_after: "\u2026"
     },
     "word_position": 100
    },
    {"count": 3,
     "references": [
         "pone.0000000-Doe1",
         "pone.0000000-Doe2",
         "pone.0000000-Doe3"
     ],
     "section": "Introduction",
     "context": {
         text_before: "Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. ",
         citation: "[1]-[3]",
         text_after: " Venison filet mignon exercitation adipisicing meatloaf veniam. ",
         ellipses_after: "\u2026"
     },
     "word_position": 150
    }
];

var citationFixtureHTML = "Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. [<a href='#pone.0000000-Doe1'>1</a>] Venison filet mignon exercitation adipisicing meatloaf veniam. Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. [<a href='#pone.0000000-Doe1'>1</a>], [<a href='#pone.0000000-Doe2'>2</a>] Venison filet mignon exercitation adipisicing meatloaf veniam Bacon ipsum dolor sit amet jerky pork loin pariatur pork chop, salami do aliqua fatback. [<a href='#pone.0000000-Doe1'>1</a>]-[<a href='#pone.0000000-Doe3'>3</a>] Venison filet mignon exercitation adipisicing meatloaf veniam <ol class='references'><li><a id='pone.0000000-Doe1'/>Doe1</a></li><li><a id='pone.0000000-Doe2'/>Doe2</a></li><li><a id='pone.0000000-Doe3'/>Doe3</a></li></ol>";

test("citationIterator", function() {
    citationSelector = "a[href^='#pone.0000000']";
    var $fixture = $("#qunit-fixture");
    $fixture.append(citationFixtureHTML);
    var handleSingle = sinon.spy();
    var handleElided = sinon.spy();
    var handleBeginElissionGroup = sinon.spy();
    var handleEndElissionGroup = sinon.spy();
    citationIterator(groups, handleSingle, handleBeginElissionGroup, handleElided, handleEndElissionGroup);
    strictEqual(handleSingle.callCount, 3);
    strictEqual($(handleSingle.getCall(0).args[0]).attr('href'), "#pone.0000000-Doe1");
    strictEqual(handleSingle.getCall(0).args[1], "pone.0000000-Doe1");
    strictEqual(handleSingle.getCall(0).args[2], 0);
    strictEqual($(handleSingle.getCall(1).args[0]).attr('href'), "#pone.0000000-Doe1");
    strictEqual(handleSingle.getCall(1).args[1], "pone.0000000-Doe1");
    strictEqual(handleSingle.getCall(1).args[2], 1);
    strictEqual($(handleSingle.getCall(2).args[0]).attr('href'), "#pone.0000000-Doe2");
    strictEqual(handleSingle.getCall(2).args[1], "pone.0000000-Doe2");
    strictEqual(handleSingle.getCall(2).args[2], 0);

    strictEqual(handleBeginElissionGroup.callCount, 1);
    strictEqual($(handleBeginElissionGroup.getCall(0).args[0]).attr('href'), "#pone.0000000-Doe1");
    strictEqual(handleBeginElissionGroup.getCall(0).args[1], "pone.0000000-Doe1");
    strictEqual(handleBeginElissionGroup.getCall(0).args[2], 2);

    strictEqual(handleElided.callCount, 1);
    strictEqual($(handleElided.getCall(0).args[0]).attr('href'), "#pone.0000000-Doe3");
    strictEqual(handleElided.getCall(0).args[1], "pone.0000000-Doe2");
    strictEqual(handleElided.getCall(0).args[2], 1);

    strictEqual(handleEndElissionGroup.callCount, 1);
    strictEqual($(handleEndElissionGroup.getCall(0).args[0]).attr('href'), "#pone.0000000-Doe1");
    strictEqual($(handleEndElissionGroup.getCall(0).args[1]).attr('href'), "#pone.0000000-Doe3");
    deepEqual(handleEndElissionGroup.getCall(0).args[2], ["pone.0000000-Doe1","pone.0000000-Doe2","pone.0000000-Doe3"]);
    deepEqual(handleEndElissionGroup.getCall(0).args[3], [2, 1, 0]);
});

test("addCitationIds", function() {
    citationSelector = "a[href^='#pone.0000000']";
    var $fixture = $("#qunit-fixture");
    $fixture.append(citationFixtureHTML);
    addCitationIds(groups);
    var cites1 = $("a[href='#pone.0000000-Doe1']");
    strictEqual($(cites1).first().attr('id'), 'ref_pone.0000000-Doe1_0');
    strictEqual($(cites1).slice(1).first().attr('id'), 'ref_pone.0000000-Doe1_1');
    strictEqual($(cites1).slice(2).first().attr('id'), 'ref_pone.0000000-Doe1_2');

    var cites2 = $("a[id^='ref_pone.0000000-Doe2_']");
    strictEqual($(cites2).first().attr('id'), 'ref_pone.0000000-Doe2_0');
    strictEqual($(cites2).slice(1).first().attr('id'), 'ref_pone.0000000-Doe2_1');

    var cites3 = $("a[href='#pone.0000000-Doe3']");
    strictEqual($(cites3).first().attr('id'), 'ref_pone.0000000-Doe3_0');
});
    
test("render mention", function() {
    var mention = MentionContext({context: {
        "ellipses_before": "…",
        "text_before": "schooling fishes [37]. To overcome the confusing defense mechanism of fish schooling, predators have had to adopt different hunting strategies ",
        "citation": "[38], [39]",
        "text_after": ".",
        "quote": "…schooling fishes [37]. To overcome the confusing defense mechanism of fish schooling, predators have had to adopt different hunting strategies [38], [39]."
    }});
    var span = TestUtils.renderIntoDocument(mention);
    var bold = TestUtils.findRenderedDOMComponentWithTag(mention, 'b');
    strictEqual(span.getDOMNode().textContent, "…schooling fishes [37]. To overcome the confusing defense mechanism of fish schooling, predators have had to adopt different hunting strategies [38], [39].");
    strictEqual(bold.getDOMNode().textContent, "[38], [39]");
});

test("get license", function() {
    strictEqual(getLicense({}), "failed-to-obtain-license");
    strictEqual(getLicense({info: {}}), "failed-to-obtain-license");
    strictEqual(getLicense({info: {license: "cc-by"}}), "cc-by");
    strictEqual(getLicense({info: {license: "CC-BY"}}), "cc-by");
});

test("mkHeadingGrouper", function() {
    var licenseGrouper = mkHeadingGrouper("license");
    strictEqual(licenseGrouper({data: {}}), "failed-to-obtain-license");
    strictEqual(licenseGrouper({data: {info:{}}}), "failed-to-obtain-license");
    strictEqual(licenseGrouper({data: {info:{license: "cc-by"}}}), "cc-by");
});
