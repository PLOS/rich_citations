/**
  * @jsx React.DOM 
  */

var doi = $('meta[name=citation_doi]').attr("content");

/* local part of the doi */
var doi_local_part = doi && doi.match(/^10.1371\/journal\.(.*)$/)[1];

/* selector that can be used to match all the a elements that are citation links */
var citationSelector = "a[href^='#" + doi_local_part + "']";
var citationFilter = function (el) {
    /* return true for refs that link to a target in the references section */
    return ($("ol.references " + jq($(this).attr("href").substring(1))).length > 0);
};

/**
 * Build a full-text index from an array of references.
 */
function buildIndex(references) {
    var idx = lunr(function () {
        this.field('title', { boost: 10 });
        this.field('body');
    });
    for (var id in references) {
        var ref = references[id];
        var doc = { id:    ref.id,
                    title: ref.info.title,
                    body:  ref.text };
        idx.add(doc);
    }
    return idx;
}

function getReferenceId (el) {
    return $("a:first", el).attr('id');
}

/**
 * Function to sort two array by their sort field, which is an array
 * of comparable things (numbers or strings) starting with the most
 * signficant.
 */
function arraySorter(a, b) {
    var retval = _.chain(_.zip(a.sort, b.sort)).map(function (x) {
        var aval = x[0];
        var bval = x[1];
        if (aval === null || bval === null) {
            return 0;
        } else if (typeof(aval) === "number") {
            return aval - bval;
        } else {
            return aval.localeCompare(bval);
        };
    }).find(function(n) { return n !== 0; }).value();
    if (retval === undefined) {
        /* all the same, return 0 */
        return 0;
    } else {
        return retval;
    }
}

/**
 * Make a sort field for this reference.
 */
function mkSortField(ref, fieldname) {
    var info = ref.info;
    if (fieldname === 'title') {
        return mkSortString(info.title);
    } else if (fieldname === 'appearance') {
        return ref.citation_groups[0].word_position;
    } else if (fieldname === 'journal') {
        return mkSortString(info.journal);
    } else if (fieldname === 'year') {
        return info.year || null;
    } else if (fieldname === 'mentions') {
        return ref.mentions;
    } else if (fieldname === 'author') {
        var first_author = info.first_author;
        return (first_author && mkSortString(first_author.last_name + " " + first_author.first_name)) || null;
    } else if (fieldname === "index") {
        return ref.index;
    } else {
        return null;
    }
}

/**
 * Sorts references by the given fieldname. Returns an object
 * containing two values, sorted and unsortable.
 */
function sortReferences (refs, by, showRepeated) {
    /* data structure to use for sorting */
    var t = [];
    if (showRepeated && by === 'appearance') {
        /* special case, show repeated citations in order of appearance */
        _.each(refs, function(ref) {
            _.each(ref.citation_groups, function (group) {
                t.push({ data: ref,
                         group: group,
                         sort: [group.word_position, ref.index]});
                  
            });
        });
    } else {
        t = _.map(refs, function(ref) {
            return { data: ref,
                     group: ref.citation_groups[0],
                     sort: [mkSortField(ref, by), ref.index] };
        });
    }
    var retval = _.partition(t, function (ref) {
        return (ref.sort[0] !== null); // split into sortable, unsortable
    }).map(function(a) {
        return a.sort(arraySorter); // sort both (unsortable will be sorted by index)
    });
    return {sorted:     retval[0],
            unsortable: retval[1]};
}

/**
 * Make a function suitable for filtering a reference list from a
 * given index and a search string.
 */
function mkSearchResultsFilter(idx, filterText) {
    if (filterText) {
        var resultHash = {};
        idx.search(filterText).map(function (res) {
            resultHash[res['ref']] = res['score'];
        });
        return function (ref) {
            return (resultHash[ref.id] != null);
        };
    } else {
        /* by default return all results */
        return function (e) { return true; };
    }
}

/**
 * Generate random UUID that can be use as an id for generated nodes.
 */
function guid() {
    function s4() {
        return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16)
            .substring(1);
    }
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
        s4() + '-' + s4() + s4() + s4();
}

/**
 * Create a quoted selector for a given id.
 */
function jq(myid) {
    return "#" + myid.replace( /(:|\.|\[|\])/g, "\\$1" );
}

/* custom pipeline with more limited stop words & no stemming for sorting */
var sortPipeline = new lunr.Pipeline();
sortPipeline.add(
    lunr.trimmer,
    function (token) {
        if (["the","a","an"].indexOf(token) === -1) return token;
    }
);

/**
 * Process a string for sorting.
 */
function mkSortString(s) {
    if (!s) { return null; }
    else { return sortPipeline.run(lunr.tokenizer(s)).join(" "); }
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
    return retval;
}

var Reference = React.createClass({
    getInitialState: function() {
        return { showAppearances: false };
    },
    getDefaultProps: function() {
        return {
            suppressMention: null
        };
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
                    if (this.props.suppressMention === mention.index) {
                        return <p key={ "mention" + mention.word_position } ><i>current location</i></p>;
                    } else {
                        return <p key={ "mention" + mention.word_position } >
                            <a href={ "#ref_" + ref.id + "_" + mention.index } >{ mention.context }</a>
                            </p>;
                    }
                }.bind(this));
                return <div key={ "appearance_list_" + ref.id + "-" + key } ><p><strong>{ key }</strong></p>
                    { mentions }
                </div>;
            }.bind(this));
        }
        var label;
        var isSelected = ($.param.fragment() === ref.id);
        if (this.props.showLabel) {
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
        var appearanceToggle;
        var times = ref.mentions === 1 ? "time" : "times";
        if (ref.mentions === 1 && this.props.suppressMention !== null) {
            appearanceToggle = <span>Appears { ref.mentions} { times } in this paper.</span>;
        } else {
            appearanceToggle = <a onClick={this.handleClick} href="#">Appears { ref.mentions } { times }  in this paper.
                { this.state.showAppearances ? " ▼ " : " ▶ " }
            </a>;
        }
        return <div id={ 'reference_' + this.props.reference.id } className={ className }>
            { label }
            <span dangerouslySetInnerHTML={ {__html: ref.html} } />
            { selfCiteFlag }
            { appearanceToggle }
            { appearanceList }
            </div>;
    }
});

var SortedReferencesList = React.createClass({
    useHeadings: function() {
        return ["journal","appearance"].indexOf(this.props.current.by) !== -1;
    },
    headingGrouper: function (ref) {
        var by = this.props.current.by;
        /* handle reference groups */
        if ($.type(ref) === 'array') {
            ref = ref[0];
        }
        if (by === "journal") {
            return ref.data.info.journal;
        } else if (by === "appearance") {
            return ref.group.section;
        } else {
            return null;
        }
    },
    renderReferenceList: function(refs) {
        if ($.type(refs) === 'array') {
            if ($.type(refs[0]) === 'array') {
                /* grouped citations */
                return _.map(refs, function (group) {
                    var key = "citation_group_" + group[0].group.word_position;
                    return <div className="citationGroup" key={ key }>{this.renderReferenceList(group) }</div>;
                }.bind(this));
            } else {
                return <ol className="references">{ _.map(refs, this.renderReferenceItem) }</ol>;
            }
        } else {
            return _.map(refs, function (value, key) {
                return <div key={ "citation_group_" + key }>
                    <p><strong>{ key }</strong></p>
                    { this.renderReferenceList(value) }
                </div>;
            }.bind(this));
        }
    },
    updateHighlighting: function () {
        /* clear old highlights */
        setTimeout(function () {
            $("ol.references").unhighlight();
        }.bind(this), 1);

        /* after rendering, highlight filtered text */
        if (this.props.filterText) {
            setTimeout(function () {
                var tokens = lunr.tokenizer(this.props.filterText);
                /* highlight raw tokens & stemmed */
                _.each($.unique(tokens.concat(this.idx.pipeline.run(tokens))), function (s) {
                    $("ol.references").highlight(s);
                });
            }.bind(this), 1);
        }
    },
    renderReferenceItem: function(ref) {
        /* Build elements for react */
        return <li key={ "" + ref.data.id + ref.group.word_position }><Reference reference={ ref.data } showLabel={ true } /></li>;
    },
    renderSortedReferenceList: function (sorted) {
        if (this.props.current.order == "desc") {
            sorted = sorted.reverse();
        }
        if (this.props.showRepeated && this.props.groupCitations ) {
            sorted = _.chain(sorted).groupBy(function(ref) {
                return ref.group.word_position;
            }).values().sortBy(function (refs) {
                return refs[0].group.word_position;
            }).value();
        }
        if (this.useHeadings()) {
            sorted = _.groupBy(sorted, this.headingGrouper);
        }
        return <div>{ this.renderReferenceList(sorted) }</div>;
    },
    render: function() {
        var filtered = _.filter(this.props.references, this.props.searchResultsFilter);
        var results = sortReferences(filtered, this.props.current.by, this.props.showRepeated);
        this.updateHighlighting();

        return <div>
            { (results.unsortable.length > 0) ? <p>And <a href="#unsortable">{ results.unsortable.length } unsortable items</a></p> : ""}
            { this.renderSortedReferenceList(results.sorted) }
            { (results.sorted.length === 0 && results.unsortable.length === 0) ? <div>No results found.</div> : "" }
            { (results.unsortable.length > 0 ) ? <h5 id="unsortable">Unsortable</h5> : ""}
            <ol className="references">{ results.unsortable.map(this.renderReferenceItem) }</ol>
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
            defaultOrder: "asc",
            toggleable: false
        };
    },
    handleClick: function() {
        var order = this.props.defaultOrder;
        if (this.props.toggleable && (this.props.current.by === this.props.by)) {
            order = (this.props.current.order === "asc") ? "desc" : "asc";
        }
        this.props.onClick(this.props.by, order);
        return false;
    },
    render: function() {
        if (!this.props.toggleable && (this.props.current.by === this.props.by)) {
            return <span>{this.props.name}</span>;
        } else {
            return <a href="#" onClick={this.handleClick}>{this.props.name}</a>;
        }
    }
});

var Toggle = React.createClass({
    handleClick: function() {
        this.props.onClick();
        return false;
    },
    render: function () {
        var toggle = this.props.enabled ? "☑" : "☐";
        return <p><a href="#" onClick={ this.handleClick }>{ toggle } { this.props.children }</a></p>;
    }
});

var ReferencePopover = React.createClass({
    getInitialState: function() {
        return {};
    },
    render: function() {
        var references = _.map(_.zip(this.props.references, this.props.suppressMentions), function(d) {
            return <Reference
              reference={ d[0] }
              qtip={ this.props.qtip }
              key={ d[0].id }
              showLabel={ this.props.references.length > 1 }
              suppressMention={ d[1] } />;
        }.bind(this));
        return <div>{ references }</div>;
    }
});
        
var ReferencesApp = React.createClass({
    getInitialState: function() {
        return {sort: { by: "appearance", order: "asc" },
                filterText: '',
                showRepeated: false,
                groupCitations: false};
    },
    componentWillMount: function() {
        $(citationSelector).filter(citationFilter).on( "click", function() {
            this.setState({ filterText: "" });
        }.bind(this));
    },
    componentDidMount: function() {
        /* build full-text index */
        this.idx = buildIndex(this.props.references);

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
    toggleShowRepeated: function() {
        this.setState({showRepeated: !this.state.showRepeated});
        return false;
    },
    toggleGroupCitations: function() {
        this.setState({groupCitations: !this.state.groupCitations});
        return false;
    },
    render: function() {
        return <div>
            <SearchBar filterText={this.state.filterText} onSearchUpdate={this.handleSearchUpdate}/>
            <div class="sorter">
            <strong>Sort by:</strong>
            <ul className="sorters">
            <li><Sorter name="Appearance"    by="appearance"    current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Title"    by="title"    current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Author"   by="author"   current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Year"     by="year"     current={this.state.sort} onClick={this.handleSorterClick} defaultOrder="desc" toggleable={ true } /> | </li>
            <li><Sorter name="Mentions" by="mentions" current={this.state.sort} onClick={this.handleSorterClick} defaultOrder="desc"/> | </li>
            <li><Sorter name="Journal"  by="journal"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            </div>
            { (this.state.sort.by === 'appearance') ?
              <div>
                <Toggle onClick={ this.toggleShowRepeated } enabled={ this.state.showRepeated } >
                  Show repeated citations
                </Toggle>
                <Toggle onClick={ this.toggleGroupCitations } enabled={ this.state.groupCitations } >
                  Group citations
                </Toggle>
              </div>
              : "" }
            <SortedReferencesList
              current={this.state.sort}
              references={this.props.references}
              filterText={this.state.filterText}
              searchResultsFilter={mkSearchResultsFilter(this.idx, this.state.filterText)}
              showRepeated={ this.state.showRepeated }
              groupCitations={ this.state.groupCitations }
            />
            </div>;
    }
});

/**
 * Function that wraps nodes between startId and endId in a span with
 * a given id.
 */
function wrapSpan(startId, endId, spanId) {
    if (startId === endId) {
        $(jq(startId)).wrapAll("<span id='" + popoverSpanId + "'/>");
    } else {
        var startSelector = jq(startId);
        var endSelector = jq(endId);
        $(startSelector).parent().children().each(function(){
            var set = $();
            var nxt = this;
            var inSpan = false;
            while(nxt) {
                if (!inSpan) {
                    if ($(nxt).is(startSelector)) {
                        set.push(nxt);
                        inSpan = true;
                    }
                } else {
                    set.push(nxt);
                    if ($(nxt).is(endSelector)) {
                        break;
                    }
                }
                nxt = nxt.nextSibling;
            }
            set.wrapAll("<span id='" + spanId + "'/>");
        });
    }
}

/**
 * Attach a popover to an element with a given ID containing
 * references.
 */
function mkReferencePopover(id, references, suppressMentions) {
    var popoverId = guid();
    $(jq(id)).qtip({
        content: {
            text: function(event, api) {
                setTimeout(function (){
                    React.renderComponent(<ReferencePopover references={ references } qtip={ api } suppressMentions={ suppressMentions }/>,
                                          $(jq(popoverId)).get(0));
                }.bind(this), 1);
                return "<div id='" + popoverId + "'>Loading...</div>";
            }
        },
        hide: {
            fixed: true,
            delay: 1000
        },
        style: 'qtip-wiki'
    });
}

/* if we don't load after document ready we get an error */
$(document).ready(function () {
    /* now fetch the JSON describing the paper */
    $.getJSON("/papers/" + doi + "?format=json", function(data) {
        /* build main data structure */
        var references = buildReferenceData(data);
        /* insert the container */
        $("<div id='richcites'></div>").insertBefore("#references");
        /* and drop into react */
        React.renderComponent(
            <ReferencesApp references={references} />,
            $("ol.references").get(0)
        );

        /* set up popover references */
        $(document).ready(function() {
            var groups = data.groups;
            var groupCounter = 0;
            /* track the citations encountered in a multi-citation
             group, so that we add those elided */
            var citationsEncountered = null;
            /* track the starting citation id */
            var startId;
            /* track the current count for each citation */
            var citationCounters = {};
            function incCitationCounter(referenceId) {
                if (citationCounters[referenceId] === undefined) {
                    citationCounters[referenceId] = 0;
                } else {
                    citationCounters[referenceId] = citationCounters[referenceId] + 1;
                }
            }
            $(citationSelector).filter(citationFilter).each(function() {
                /* the id of the current reference */
                var refId = $(this).attr('href').substring(1);
                incCitationCounter(refId);
                /* give this a unique id */
                var citationId = "ref_" + refId + "_" + citationCounters[refId];
                $(this).attr("id", citationId);
                /* the list of reference id for the current citation group */
                var currentGroupRefIds = groups[groupCounter].references;
                if (currentGroupRefIds.length === 1) {
                    groupCounter = groupCounter + 1;
                    mkReferencePopover(citationId, [data.references[refId]], [citationCounters[refId]]);
                } else {
                    /* in a multi-citation group */
                    if (citationsEncountered === null) {
                        /* first */
                        citationsEncountered = [refId];
                        startId = citationId;
                    } else if (refId === currentGroupRefIds[currentGroupRefIds.length-1]) {
                        /* last */
                        citationsEncountered.push(refId);
                        /* add targets for elided references */
                        var elidedReferences = _.filter(currentGroupRefIds, function (id) {
                            return (citationsEncountered.indexOf(id) == -1);
                        });
                        _.each(elidedReferences, function (refId) {
                            incCitationCounter(refId);
                            $("<a id='" + "ref_" + refId + "_" + citationCounters[refId] + "'/>").insertAfter(jq(startId));
                        });
                        groupCounter = groupCounter + 1;
                        var spanId = guid();
                        wrapSpan(startId, citationId, spanId);
                        var references = _.map(currentGroupRefIds, function(refId) { return data.references[refId]; });
                        var suppressMentions = _.map(currentGroupRefIds, function(refId) { return citationCounters[refId]; });
                        mkReferencePopover(spanId, references, suppressMentions);
                        citationsEncountered = null;
                    } else {
                        /* in the middle */
                        citationsEncountered.push(refId);
                   }
                }
            });
        });
    });
});
