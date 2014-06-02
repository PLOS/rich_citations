//= require jquery

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
                     sortableCount: 33,
                     unsortableCount: 22,
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
    ok(guid1.match("^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$"));
    ok(guid2.match("^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$"));
});
