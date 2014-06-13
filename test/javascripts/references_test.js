/** @jsx React.DOM */
//= require jquery
//= require react

var TestUtils = React.addons.TestUtils;

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
            var refNoInfo = fixture.references["pone.0067380-Wahnbaeck1"];
            strictEqual("relative importance of growth and behaviour to elasmobranch suction-feeding performance over early ontogeny", mkSortField(ref, "title"));
            strictEqual(1, mkSortField(ref, "mentions"));
            strictEqual(6487, mkSortField(ref, "appearance"));
            strictEqual("lowry d", mkSortField(ref, "author"));
            strictEqual(2008, mkSortField(ref, "year"));
            strictEqual(55, mkSortField(ref, "index"));
            strictEqual("journal of royal society interface", mkSortField(ref, "journal"));

            /* reference with no info */
            strictEqual(null, mkSortField(refNoInfo, "author"));
            strictEqual(null, mkSortField(refNoInfo, "year"));
            strictEqual(null, mkSortField(refNoInfo, "title"));
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
            strictEqual(results[0].id, "pone.0067380-Patek1");
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
                     unsortableCount: 0,
                     showRepeated: false},
                    {by: "appearance",
                     first: "pone.0067380-Clua1",
                     last: "pone.0067380-Heithaus1",
                     sortableCount: 91,
                     unsortableCount: 0,
                     showRepeated: true},
                    {by: "title",
                     first: "pone.0067380-Simon1",
                     last: "pone.0067380-Whitehead1",
                     sortableCount: 39,
                     unsortableCount: 16,
                     showRepeated: false}],
                   function (d) {
                       var refs = fixture.references;
                       var results = sortReferences(refs, d.by, d.showRepeated);
                       strictEqual(results.unsortable.length, d.unsortableCount);
                       strictEqual(results.sorted.length, d.sortableCount);
                       strictEqual(results.sorted[0].data.id, d.first);
                       strictEqual(results.sorted[results.sorted.length-1].data.id, d.last);
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

test("renderAuthorName", function() {
    strictEqual(renderAuthorName({given: "Jane", family: "Roe"}), "Roe J");
    strictEqual(renderAuthorName({given: "Mary Jane", family: "Roe"}), "Roe MJ");
    strictEqual(renderAuthorName({given: "Jane", family: "Roe Doe"}), "Roe Doe J");
    strictEqual(renderAuthorName({given: "Jane", family: "Roe-Doe"}), "Roe-Doe J");
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
    var a = {given: "Jane", family: "Roe"};
    var b = {given: "Joan", family: "Roe"};
    var c = {given: "John", family: "Doe"};
    var d = {given: "James", family: "Doe"};
    var e = {given: "Jennifer", family: "Roe"};
    /* can't make JSX transform work at the moment */
    var authorList4 = ReferenceAuthorList({authors: [a, b, c, d]});
    var authorList5 = ReferenceAuthorList({authors: [a, b, c, d, e]});
    TestUtils.renderIntoDocument(authorList4);
    TestUtils.renderIntoDocument(authorList5);
    var span4 = TestUtils.findRenderedDOMComponentWithTag(authorList4, 'span');
    var span5 = TestUtils.findRenderedDOMComponentWithTag(authorList5, 'span');
    /* all four names should display */
    strictEqual(span4.getDOMNode().textContent, "Roe J, Roe J, Doe J, Doe J");
    /* 2 refs of 5 should be hidden */
    strictEqual(span5.getDOMNode().textContent, "Roe J, Roe J, Doe J, et al.");
    /* should expand on click */
    var input = TestUtils.findRenderedDOMComponentWithTag(span5, 'button');
    TestUtils.Simulate.click(input);
    strictEqual(span5.getDOMNode().textContent, "Roe J, Roe J, Doe J, Doe J, Roe J");
});

test("abstract display", function() {
    var abs = ReferenceAbstract({ text: "foo bar baz" });
    TestUtils.renderIntoDocument(abs);
    var div = TestUtils.findRenderedDOMComponentWithTag(abs, "div");
    strictEqual(div.getDOMNode().textContent, "▶ Show abstract ");
    var input = TestUtils.findRenderedDOMComponentWithTag(abs, 'button');
    TestUtils.Simulate.click(input);
    strictEqual(div.getDOMNode().textContent, "▼ Show abstract foo bar baz");
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
