/**
  * @jsx React.DOM 
  */

var doi = $('meta[name=citation_doi]').attr("content");

var idx = lunr(function () {
    this.field('title', { boost: 10 });
    this.field('body');
});

function buildIndex(references, json) {
    var refs = getRefListById(json);
    jQuery.makeArray(references).map(function (el) {
        var id = getReferenceId(el);
        var doc = { "title" : refs[id].info.title,
                    "body"  : $(el).text(),
                    "id" : id};
        idx.add(doc);
    });
}

function getRefListById(json) {
    var l = {};
    $.each(json['references'], function (ignore, v) {
        l[v.id] = v;
    });
    return l;
}

function getReferenceInfoById(refs, id) {
    if (refs[id] == null) {
        return null;
    } else {
        return refs[id].info;
    }
}

/**
 * Build a function that can be passed to filter to remove items that
 * cannot be sorted.
 */
function mkUnsortableFilter(by, json) {
    var refs = getRefListById(json);
    return function (el) {
        var info = getReferenceInfoById(refs, getReferenceId(el));
        if (info === null) {
            return true;
        }
        else {
            return getReferenceInfoField(info, by) === null;
        }
    };
}

function getReferenceInfoField(info, fieldname) {
    var s = info[fieldname];
    if (!s || (typeof myVar != 'undefined') || s === "") {
        return null;
    } else {
        return s;
    }
}

function getReferenceId (el) {
    return $("a:first", el).attr('id');
}

/**
 * Build a function from a field and a JSON data structure as returned
 * by richcites API that can be passed to sort to sort an array of
 * references.
 */
function mkSortRefListFunction (by, json, descending=false) {
    var refs = getRefListById(json);
    var pipeline = new lunr.Pipeline();
    pipeline.add(lunr.trimmer,
                 lunr.stopWordFilter);
    return function (a, b) {
        var aref = getReferenceInfoById(refs, getReferenceId(a));
        var bref = getReferenceInfoById(refs, getReferenceId(b));
        var aval = getReferenceInfoField(aref, by);
        var bval = getReferenceInfoField(bref, by);
        // XXX too many calls to pipeline
        return pipeline.run(lunr.tokenizer(aval)).join(" ").localeCompare(pipeline.run(lunr.tokenizer(bval)).join(" "));
    };
}
                            
var Reference = React.createClass({
    render: function () {
        return <li dangerouslySetInnerHTML={{__html:this.props.html}} />;
    }
});

var SortedReferencesList = React.createClass({
    render: function() {
        var refsArray = $.makeArray(this.props.references);
        var sorted, unsorted;

        /* Index is special, we just use the original sort order. */
        if (this.props.current.by === 'index') {
            sorted = refsArray.filter(this.props.searchResultsFilter);
            unsorted = [];
        } else {
            var unsortableFilter = mkUnsortableFilter(this.props.current.by, this.props.json);
            var sortableFilter = function (el) { return !unsortableFilter(el); };
            var sortFunc = mkSortRefListFunction(this.props.current.by, this.props.json);
            unsorted = refsArray.filter(unsortableFilter).
                filter(this.props.searchResultsFilter);
            sorted = refsArray.filter(sortableFilter).sort(sortFunc).
                filter(this.props.searchResultsFilter);
        }
        
        if (this.props.current.order == "desc") { sorted = sorted.reverse(); }

        /* Build elements for react */
        var mkElementFunc = function (h) {
            return <Reference html={$(h).html()} key={getReferenceId(h)} />;
        };
        return <div>
            <ol className="references">{ sorted.map(mkElementFunc) }</ol>
            <h5>Unsortable</h5>
            <ol className="references">{ unsorted.map(mkElementFunc) }</ol>
            </div>;
    }
});

var SearchBar = React.createClass({
    handleChange: function() {
        this.props.onSearchUpdate(
            this.refs.filterTextInput.getDOMNode().value
        );
    },
    render: function() {
        return (
            <form onSubmit={this.handleSubmit}>
                <input
                    type="text"
                    placeholder="Search..."
                    value={this.props.filterText}
                    ref="filterTextInput"
                    onChange={this.handleChange}
                />
            </form>
        );
    }
});

var Sorter = React.createClass({
    handleClick: function() {
        this.props.onClick(this.props.by);
        return false;
    },
    render: function() {
        var sortorderstr = "";
        if (this.props.current.by === this.props.by) {
            sortorderstr = this.props.current.order == "asc" ? "↑" : "↓";
        }
        return <a href="#" onClick={this.handleClick}>{this.props.name}{sortorderstr}</a>;
    }
});

var ReferencesApp = React.createClass({
    getInitialState: function() {
        return {sort: { by: "index", order: "asc" },
                filterText: ''};
    },
    handleSearchUpdate: function(filterText) {
        this.setState({
            filterText: filterText
        });
    },
    handleSorterClick: function(by) {
        var newSortOrder = (this.state.sort.order == "asc") ? "desc" : "asc";
        if (this.state.sort.by != by) {
            newSortOrder = "asc";
        }
        this.setState({sort: { by: by, order: newSortOrder }});
    },
    mkSearchResultsFilter: function () {
        if (this.state.filterText) {
            var resultHash = {};
            idx.search(this.state.filterText).map(function (res) {
                return resultHash[res['ref']] = res['score'];
            });
            return function (e) {
                return (resultHash[getReferenceId(e)] != null);
            };
        } else {
            /* by default return all results */
            return function (e) { return true; };
        }
    },
    render: function() {
        return <div>
            <SearchBar filterText={this.state.filterText} onSearchUpdate={this.handleSearchUpdate}/>
            <ul>
            <li><Sorter name="Index"  by="index"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Title"  by="title"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Author" by="author" current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Year"   by="year"   current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            <SortedReferencesList current={this.state.sort} references={this.props.references} searchResultsFilter={this.mkSearchResultsFilter()} json={this.props.json}/>
            </div>;
    }
});

/* if we don't load after document ready we get an error */
$(document).ready(function () {
    var doi = $('meta[name=citation_doi]').attr("content");
    /* now fetch the JSON describing the paper */
    $.getJSON("/papers/" + doi + "?format=json", function(data) {
        var references = $("ol.references li");
        /* build full-text index */
        buildIndex(references, data);
        /* insert the container */
        $("<div id='richcites'></div>").insertBefore("#references");
        /* and drop into react */
        React.renderComponent(
            <ReferencesApp references={references} json={data}/>,
            $("ol.references").get(0)
        );
    });
});
