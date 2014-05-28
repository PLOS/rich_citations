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
    var ref = {
        mentions: 5,
        index: 2,
        citation_groups: [
            { word_position: 13 }
        ],
        info: {
            title: "Hello, world",
            first_author: {
                last_name: "Doe",
                first_name: "John"
            },
            year: 2013
        }
    };
    strictEqual("hello world", mkSortField(ref, "title"));
    strictEqual(5, mkSortField(ref, "mentions"));
    strictEqual(13, mkSortField(ref, "appearance"));
    strictEqual("doe john", mkSortField(ref, "author"));
    strictEqual(2013, mkSortField(ref, "year"));
    /* anything else should return index */
    strictEqual(2, mkSortField(ref, "foobar"));
});
