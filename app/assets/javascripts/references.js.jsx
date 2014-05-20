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
    $.each(json.references, function (k, v) {
        retval[k] = v;
        // id lookup not working?
        var selector = "[name='" + v.id + "']";
        var html = $(selector).parent().first().remove("span.label").html();
        // cannot get this to work properly in jquery
        html = html.replace(/<span class="label">[^<]+<\/span>/, '');
        retval[k]['html'] = html;
        retval[k]['text'] = $(selector).parent().first().text();
    });

    var i = 1;
    $("ol.references li").each(function (el) {
        var id = getReferenceId($(this));
        retval[id]['index'] = i;
        i = i + 1;
    });

    /* make fields for sorting */
    function mkSortString(s) {
        if (!s) { return null; }
        else { return idx.pipeline.run(lunr.tokenizer(s)).join(" "); }
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
    getInitialState: function() {
        return { showAppearances: false };
    },
    componentDidUpdate: function() {
        if (this.props.qtip) {
            this.props.qtip.reposition();
        }
    },
    handleClick: function() {
        this.setState( { showAppearances: !this.state.showAppearances });
        return false;
    },
    /**
     * Return a function to jump to the nth (0-index) appearance of a citation.
     */
    mkSelectAppearanceFunction: function (refId, n) {
        return function () {
            var targetSelector = "a[href='#" + refId + "']";
            $(document).scrollTop( $($(targetSelector)[n]).offset().top);
            return false;
        };
    },
    render: function () {
        var ref = this.props.reference;
        var selfCiteFlag = null;
        if (ref.self_citations) {
            selfCiteFlag = <span className="selfcitation">Self-citation</span>;
        }
        var appearanceList;
        if (this.state.showAppearances) {
            /* generate an index (count) for each citation group; e.g., the 2nd citation of a given reference in the document */
            var citationGroupsWithIndex = _.map(ref.citation_groups, function (group, index) {
                group['index'] = index;
                return group;
            });
            /* group each citation group by the section it is in */
            var citationGroupsBySection = _.groupBy(citationGroupsWithIndex, function(g) { return g.section; });
            appearanceList = _.map(citationGroupsBySection, function(value, key) {
                var mentions = _.map(value, function (mention) {
                    return <p key={ "mention" + mention.word_position } >
                        <a href={ "#citation_" + ref.id + "_" + mention.index } >{ mention.context }</a>
                        </p>;
                }.bind(this));
                return <div key={ "appearance_list_" + ref.id + "-" + key } ><p><strong>{ key }</strong></p>
                    { mentions }
                </div>;
            }.bind(this));
        }
        var label;
        var isSelected = ($.param.fragment() === ref.id);
        if (!this.props.qtip) {
            /* not in popover */
            /* check if this is the selected anchor */
            if (isSelected) {
                label = <span className="label"><a href="#" onClick={ function() { window.history.back(); return false; } }>{ ref.index }</a>.</span>;
            } else {
                label = <span className="label">{ ref.index }.</span>;
            }
        }
        var className = "reference";
        if (isSelected) {
            className = className + " selected";
        }
        return <div id={ 'reference_' + this.props.reference.id } className={ className }>
            { label }
            <span dangerouslySetInnerHTML={ {__html: ref.html} } />
            { selfCiteFlag }
            <a onClick={this.handleClick} href="#">Appears { ref.mentions } times in this paper.
            { this.state.showAppearances ? "▼" : "▶" }
            </a>
            { appearanceList }
            </div>;
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
    isGrouped: function() {
        return ["journal"].indexOf(this.props.current.by) !== -1;
    },
    grouper: function (ref) {
        var by = this.props.current.by;
        if (by === "journal") {
            return ref.info.journal;
        } else if (by === "index") {
            // TODO: group when displaying repeated cites
            return null;
        } else {
            return null;
        }
    },
    renderGroupedReferenceList: function(refs) {
        var grouped = _.groupBy(refs, this.grouper);
        var retval = _.map(grouped, function (value, key) {
            return <div key={ "citation_group_" + key }>
                <p><strong>{ key }</strong></p>
                <ol> { _.map(value, this.renderReferenceItem) } </ol>
                </div>;
        }.bind(this));
        return retval;
    },
    updateHighlighting: function () {
        /* clear old highlights */
        setTimeout(function () {
            $("ol.references").unhighlight();
        }.bind(this), 1);

        /* after rendering, highlight filtered text */
        if (this.props.filterText) {
            setTimeout(function () {
                _.each(idx.pipeline.run(lunr.tokenizer(this.props.filterText)), function (s) {
                    $("ol.references").highlight(s);
                });
            }.bind(this), 1);
        }
    },
    renderReferenceItem: function(ref) {
        /* Build elements for react */
        return <li key={ref.id}><Reference reference={ ref } /></li>;
    },
    renderSortedReferenceList: function (refs) {
        var sorted = refs.filter(this.sortableFilter).sort(this.sorter);

        if (this.props.current.order == "desc") { sorted = sorted.reverse(); }

        if (this.isGrouped()) {
            return <div>{ this.renderGroupedReferenceList(sorted) }</div>;
        } else {
            return <ol className="references">{ sorted.map(this.renderReferenceItem) }</ol>;
        }
    },
    render: function() {
        var refs = $.map(this.props.references, function(val, key) { return val; }).
                filter(this.props.searchResultsFilter);

        var unsorted = refs.filter(this.unsortableFilter);

        this.updateHighlighting();

        var unsortableLink, unsortableHeader;
        if (unsorted.length > 0) {
            unsortableLink = <p>And <a href="#unsortable">{ unsorted.length } unsortable items</a></p>;
            unsortableHeader = <h5 id="unsortable">Unsortable</h5>;
        }
        return <div>
            { unsortableLink }
            { this.renderSortedReferenceList(refs) }
            { unsortableHeader }
            <ol className="references">{ unsorted.map(this.renderReferenceItem) }</ol>
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
        return <div><Reference reference={this.props.reference} qtip={this.props.qtip} /></div>;
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
    componentDidMount: function() {
        $(window).bind('hashchange', function(e) {
            /* redraw when the fragment URL changes, to faciliate the link to the back button */
            this.setState({});
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
            <li><Sorter name="Year"     by="year"     current={this.state.sort} onClick={this.handleSorterClick} order="desc"/></li>
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

        /* set up monitor to check if we are accessing a "citation_ID_n" 
         fragment identifier, which will point to the nth citation of reference ID */
        $(window).bind('hashchange', function(e) {
            var url = $.param.fragment();
            var md;
            if ((md = url.match("^citation_(.*)_([0-9]+)$"))) {
                var n = parseInt(md[2], 10);
                var targetSelector = "a[href='#" + md[1] + "']";
                $(document).scrollTop( $($(targetSelector)[n]).offset().top);
            }
        });
        
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
                                React.renderComponent(<ReferencePopup reference={ references[refid] } qtip={ api } />,
                                                      $(selector).get(0));
                            }.bind(this), 1);
                            return "<div id='" + elementid + "'>Loading...</div>";
                        }
                    },
                    hide: {
                        fixed: true,
                        delay: 1000
                    },
                    position: { viewport: $(window) },
                    style: 'qtip-wiki'
                });
                popoverCounter = popoverCounter + 1;
            });
        });
    });
});
