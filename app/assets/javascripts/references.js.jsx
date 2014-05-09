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

    /* make fields for sorting */
    var pipeline = new lunr.Pipeline();
    pipeline.add(lunr.trimmer,
                 lunr.stopWordFilter);
    function mkSortString(s) {
        if (!s) { return null; }
        else { return pipeline.run(lunr.tokenizer(s)).join(" "); }
    }
    $.each(retval, function (ignore, v) {
        v['sortfields'] = {};
        v['sortfields']['title'] = mkSortString(v.info.title);
        v['sortfields']['index'] = v.index;
        v['sortfields']['journal'] = mkSortString(v.info.journal);
        v['sortfields']['year'] = mkSortString(v.info.year);
        v['sortfields']['mentions'] = v.mentions;
        console.log(v);
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
     * Function that can be passed to filter to remove items that
     * cannot be sorted.
     */
    sortableFilter: function(ref) {
        console.log(ref.sortfields[this.props.current.by]);
        var v = ref.sortfields[this.props.current.by];
        if (typeof(v) === "undefined" || v === null || v === "") {
            return false;
        } else {
            return true;
        }
    },
    /**
     * Function to pass to filter to remove items that can be sorted.
     */
    unsortableFilter: function (ref) {
        return !this.sortableFilter(ref);
    },
    /**
     * Function to sort by the curre
     */
    sorter: function(a, b) {
        var aval = a.sortfields[this.props.current.by];
        var bval = b.sortfields[this.props.current.by];
        console.log(aval);
        if (typeof(aval) === "number") {
            return aval - bval;
        } else {
            return aval.localeCompare(bval);
        };
    },
    render: function() {
        var refs = $.map(this.props.references, function(val, key) { return val; }).
                filter(this.props.searchResultsFilter);

        var unsorted = refs.filter(this.unsortableFilter);
        var sorted = refs.filter(this.sortableFilter).
                sort(this.sorter);
        
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
    getDefaultProps: function() {
        return {
            defaultOrder: "asc"
        };
    },
    handleClick: function() {
        this.props.onClick(this.props.by, this.props.defaultOrder);
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
    handleSorterClick: function(by, defaultOrder) {
        var newSortOrder = (this.state.sort.order == "asc") ? "desc" : "asc";
        if (this.state.sort.by != by) {
            newSortOrder = defaultOrder;
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