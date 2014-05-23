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

