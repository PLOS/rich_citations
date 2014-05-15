/**
  * @jsx React.DOM 
  */

var doi = $('meta[name=citation_doi]').attr("content");

/* selector that can be used to match all the a elements that are citation links */

var citationSelector = "a[href^='#" + doi.match(/^10.1371\/journal\.(.*)$/)[1] + "']";

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
        // TODO: use lastname, first name when available
        v['sortfields']['author'] = v.info.authors && mkSortString(v.info.authors[0]['fullname'] );
    });

return retval;
}

var Reference = React.createClass({
    render: function () {
        var self_cite_flag = null;
        if (this.props.reference.self_citations) {
            self_cite_flag = <span className="selfcitation">Self-citation</span>;
        }
        
        return <span id={'reference-' + this.props.reference.id}>
            <span dangerouslySetInnerHTML={{__html:this.props.reference.html}} />
            {self_cite_flag}
        </span>;
    }
});

var SortedReferencesList = React.createClass({
    /**
     * Function that can be passed to filter to remove items that
     * cannot be sorted.
     */
    sortableFilter: function(ref) {
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
            return <li key={ref.id}><Reference reference={ref} /></li>;
        };

        /* clear old highlights */
        setTimeout(function () {
            $("ol.references").unhighlight();
        }.bind(this), 1);
        /* after rendering, highlight filtered text */
        if (this.props.filterText) {
            setTimeout(function () {
                $("ol.references").highlight(this.props.filterText);
            }.bind(this), 1);
        }
        var unsortableLink, unsortableHeader;
        if (unsorted.length > 0) {
            unsortableLink = <p>And <a href="#unsortable">{ unsorted.length } unsortable items</a></p>;
            unsortableHeader = <h5 id="unsortable">Unsortable</h5>;
        }
        return <div>
            { unsortableLink }
            <ol className="references">{ sorted.map(mkElementFunc) }</ol>
            { unsortableHeader }
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
            order: "asc"
        };
    },
    handleClick: function() {
        this.props.onClick(this.props.by, this.props.order);
        return false;
    },
    render: function() {
        if (this.props.current.by === this.props.by) {
            return <span>{this.props.name}</span>;
        } else {
            return <a href="#" onClick={this.handleClick}>{this.props.name}</a>;
        }
    }
});

var ReferencePopup = React.createClass({
    getInitialState: function() {
        return {};
    },
    render: function() {
        return <div><Reference reference={this.props.reference}/></div>;
    }
});
        
var ReferencesApp = React.createClass({
    getInitialState: function() {
        return {sort: { by: "index", order: "asc" },
                filterText: ''};
    },
    componentWillMount: function() {
        $(citationSelector).on( "click", function() {
            this.setState({ filterText: "" });
        }.bind(this));
    },
    handleSearchUpdate: function(filterText) {
        this.setState({
            filterText: filterText
        });
    },
    handleSorterClick: function(by, order) {
        this.setState({sort: { by: by, order: order }});
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
            <li><Sorter name="Mentions" by="mentions" current={this.state.sort} onClick={this.handleSorterClick} order="desc"/></li>
            <li><Sorter name="Journal"  by="journal"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            <SortedReferencesList
              current={this.state.sort}
              references={this.props.references}
              filterText={this.state.filterText}
              searchResultsFilter={this.mkSearchResultsFilter()} />
            </div>;
    }
});


/* if we don't load after document ready we get an error */
$(document).ready(function () {
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

        /* set up popover references */
        $(document).ready(function() {
            var popoverCounter = 1;
            $(citationSelector).each(function() {
                var refid = $(this).attr('href').substring(1);
                var elementid = 'popup' + popoverCounter;
                var selector = '#' + elementid;
                $(this).qtip({
                    content: {
                        text: function(event, api) {
                            setTimeout(function (){
                                React.renderComponent(<ReferencePopup reference={references[refid]} />,
                                                      $(selector).get(0));
                            }.bind(this), 1);
                            return "<div id='" + elementid + "'>Loading...</div>";
                        }
                    },
                    position: {
                        viewport: $(window)
                    },
                    style: 'qtip-wiki'
                });
                popoverCounter = popoverCounter + 1;
            });
        });
    });
});
