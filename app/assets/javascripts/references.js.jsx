/**
  * @jsx React.DOM 
  */

var doi = $('meta[name=citation_doi]').attr("content");

var idx = lunr(function () {
    this.field('title', { boost: 10 });
    this.field('body');
});

function buildIndex(references) {
    for (var id in references) {
        var ref = references[id];
        var doc = { id:    ref.id,
                    title: ref.info.title,
                    body:  ref.text };
        idx.add(doc);
    }
}

function getReferenceId (el) {
    return $("a:first", el).attr('id');
}

/** 
 * Merge citation reference li elements and JSON data.
 */
function buildReferenceData(json, elements) {
    var retval = {};
    /* first we need a quick lookup of the html elements by id */
    var elementsById = {};
    $("ol.references li").each(function (el) {
        elementsById[getReferenceId($(this))] = $(this);
    });
    /* now get each thing from the JSON */
    $.each(json['references'], function (ignore, v) {
        retval[v.id] = v;
        retval[v.id]['html'] = $(elementsById[v.id]).html();
        retval[v.id]['text'] = $(elementsById[v.id]).text();
    });
    var i = 0;
    $("ol.references li").each(function (el) {
        var id = getReferenceId($(this));
        retval[id]['index'] = i;
        i = i + 1;
    });
    return retval;
}

var Reference = React.createClass({
    render: function () {
        return <li dangerouslySetInnerHTML={{__html:this.props.html}} />;
    }
});

var SortedReferencesList = React.createClass({
    /**
     * Build a function that can be passed to filter to remove items that
     * cannot be sorted.
     */
    mkUnsortableFilter: function(extractor) {
        return function (el) {
            var v = extractor(el);
            if (typeof(v) === "undefined" || v === null || v === "") {
                return true;
            } else {
                return false;
            }
        };
    },
    /**
     * sort definitions, consists of a function to extract the field
     * to sort and a type, either "numeric" or "alphabetic"
     */
    sorts: {
        index: {
            extractor: function (ref) {
                return ref.index;
            },
            sortStyle: "numeric"
        },
        title: {
            extractor: function (ref) {
                return ref.info.title;
            },
            sortStyle: "alphabetic"
        },
        year: {
            extractor: function (ref) {
                return parseInt(ref.info.year);
            },
            sortStyle: "numeric"
        },
        author: {
            extractor: function(ref) {
                return ref.info.authors[0].fullname;
            },
            sortStyle: "alphabetic"
        },
        mentions: {
            extractor: function(ref) {
                return ref.mentions;
            },
            sortStyle: "numeric"
        },
        journal: {
            extractor: function(ref) {
                return ref.info.journal;
            },
            sortStyle: "alphabetic"
        }
        
    },
    /**
     * Build a sort function from a sort definition, as defined in `sorts` above.
     */
    mkSortFunc: function(o) {
        var extractor = o.extractor;
        if (o.sortStyle === "numeric") {
            return function (a,b) {
                return extractor(a) - extractor(b);
            };
        } else {
            var pipeline = new lunr.Pipeline();
            pipeline.add(lunr.trimmer,
                         lunr.stopWordFilter);
            return function (a, b) {
                var aval = pipeline.run(lunr.tokenizer(extractor(a))).join(" ");
                var bval = pipeline.run(lunr.tokenizer(extractor(b))).join(" ");
                return aval.localeCompare(bval);
            };
        }
    },
    render: function() {
        var refsArray = $.map(this.props.references, function(val, key) { return val; });
        var unsortableFilter = this.mkUnsortableFilter(this.sorts[this.props.current.by].extractor);
        var sortableFilter = function (el) { return !unsortableFilter(el); };
        var unsorted = refsArray.filter(unsortableFilter).
            filter(this.props.searchResultsFilter);
        var sorted = refsArray.filter(sortableFilter).
                sort(this.mkSortFunc(this.sorts[this.props.current.by])).
                filter(this.props.searchResultsFilter);
        
        if (this.props.current.order == "desc") { sorted = sorted.reverse(); }

        /* Build elements for react */
        var mkElementFunc = function (ref) {
            return <Reference html={ref.html} key={ref.id} />;
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
            <form onSubmit={function(){return false;}}>
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
                resultHash[res['ref']] = res['score'];
            });
            return function (ref) {
                return (resultHash[ref.id] != null);
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
            <li><Sorter name="Index"    by="index"    current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Title"    by="title"    current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Author"   by="author"   current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Year"     by="year"     current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Mentions" by="mentions" current={this.state.sort} onClick={this.handleSorterClick} defaultOrder="desc"/></li>
            <li><Sorter name="Journal"  by="journal"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            <SortedReferencesList current={this.state.sort} references={this.props.references} searchResultsFilter={this.mkSearchResultsFilter()} />
            </div>;
    }
});

/* if we don't load after document ready we get an error */
$(document).ready(function () {
    var doi = $('meta[name=citation_doi]').attr("content");
    /* now fetch the JSON describing the paper */
    $.getJSON("/papers/" + doi + "?format=json", function(data) {
        /* build main data structure */
        var references = buildReferenceData(data);
        /* build full-text index */
        buildIndex(references);
        /* insert the container */
        $("<div id='richcites'></div>").insertBefore("#references");
        /* and drop into react */
        React.renderComponent(
            <ReferencesApp references={references} />,
            $("ol.references").get(0)
        );
    });
});
