//= require jquery

fixture.preload("journal.pone.0067380.html", "journal.pone.0067380.json");

module("rich citations javascript", {
  setup: function() {
      this.fixtures = fixture.load("journal.pone.0067380.html", "journal.pone.0067380.json", true);
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
    var ref = this.fixtures[1].references["pone.0067380-Lowry1"];
    var refNoInfo = this.fixtures[1].references["pone.0067380-Wahnbaeck1"];
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
