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

function formatAuthorNameInverted (author) {
    if (author.literal) {
        return author.literal;
    } else if (author.given && author.family) {
        return author.family + ", " + author.given;
    } else {
        return "[unknown]";
    }
}

/**
 * Return a rendered string for displaying a given author. Turns given
 * names into initials, e.g. Jane Roe -> Roe J
 */
function formatAuthorNameInvertedInitials (author) {
    if (author.literal) {
        return author.literal;
    } else if (author.given && author.family) {
        var initials = _.map(author.given.split(/\s+/), function(n) { return n[0]; }).
                join("").toUpperCase();
        return author.family + " " + initials;
    } else {
        return "[unknown]";
    }
}

/**
 * Build a full-text index from an array of references.
 */
function buildIndex(references) {
    var idx = lunr(function () {
        this.field('title', { boost: 10 });
        this.field('author');
        this.field('journal');
        this.field('body');
    });
    for (var id in references) {
        var ref = references[id];
        var doc = { id:    ref.id,
                    author: _.map(ref.info.author, formatAuthorNameInverted).join(" "),
                    title: ref.info.title,
                    journal: ref.info['container-title'],
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
        /* if no references in paper, sort at end */
        return (ref.citation_groups && ref.citation_groups[0].word_position) || 99999999;
    } else if (fieldname === 'journal') {
        return mkSortString(info['container-title']);
    } else if (fieldname === 'year') {
        return (info.issued && info.issued["date-parts"] && info.issued["date-parts"][0][0]) || null;
    } else if (fieldname === 'mentions') {
        return ref.mentions;
    } else if (fieldname === 'author') {
        var first_author = info.author && info.author[0];
        return (first_author && mkSortString(formatAuthorNameInverted(first_author))) || null;
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
                     group: (ref.citation_groups && ref.citation_groups[0]) || "References",
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
    var tokens = idx.pipeline.run(lunr.tokenizer(filterText));
    if (tokens.length > 0) {
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
        var html = $(jq(v.id)).parent().first().remove("span.label").html();
        // cannot get this to work properly in jquery
        html = html.replace(/<span class="label">[^<]+<\/span>/, '');
        retval[k]['html'] = html;
        retval[k]['text'] = $(jq(v.id)).parent().first().text();
    });
    return retval;
}

/**
 * Simple wrapper to either return children or an empty span depending
 * on the truth-value of test.
 */
var Maybe = React.createClass({
    render: function() {
        if (this.props.test) {
            return <span>{ this.props.children }</span>;
        } else {
            return <span/>;
        }
    }
});

var ReferenceAbstract = React.createClass({
    getInitialState: function() {
        return { show: false };
    },
    handleClick: function() {
        this.setState({ show: !this.state.show });
        return false;
    },
    render: function() {
        if (this.props.text) {
            var toggle = <button className="non-button" onClick={ this.handleClick }>{ this.state.show ? "▼" : "▶" } Show abstract </button>;
            if (this.state.show) {
                return <div>{ toggle }<p className="abstract">{ this.props.text }</p></div>;
            } else {
                return <div>{ toggle }</div>;
            }
        } else {
            return <div></div>;
        }
    }
});

/**
 * Return the correct ordinal suffix (e.g., nd, th) for a given number.
 */
function ordinal(n) {
    var n_mod_100 = (n % 100);
    if (n_mod_100 === 11 || n_mod_100 === 12 || n_mod_100 === 13) {
        return "th";
    } else {
        var n_mod_10 = (n % 10);
        if (n_mod_10 === 1) {
            return "st";
        } else if (n_mod_10 === 2) {
            return "nd";
        } else if (n_mod_10 === 3) {
            return "rd";
        } else {
            return "th";
        }
    }
}

/**
 * Turn a number into an ordinal string, e.g. 1st, 2nd, 3rd.
 */
function ordinalStr(n) {
    return "" + n + ordinal(n);
}

/**
 * Class that enables a revealable toggle.
 */
var Revealable = React.createClass({
    getInitialState: function() {
        return { show: false };
    },
    handleClick: function() {
        this.setState({ show: !this.state.show });
        return false;
    },
    render: function() {
        return <div className="appearance-toggle"><button className="non-button" onClick={ this.handleClick }>
            { this.state.show ? "▼" : "▶" } { this.props.revealText}</button>
            { this.state.show ? this.props.children : "" }
        </div>;
    }
});

/**
 * Class to handle an appearance list in a popover or reference list.
 */
var ReferenceAppearanceListRevealable = React.createClass({
    getDefaultProps: function() {
        return { currentMention: null };
    },
    inPopover: function() {
        return (this.props.currentMention !== null);
    },
    appearanceText: function() {
        var txt = "";
        if (this.inPopover()) {
            txt += ordinalStr(this.props.currentMention + 1) + " of ";
        }
        txt += this.props.reference.mentions;
        if (this.props.reference.mentions > 1) {
            txt += " appearances"; 
        } else {
            txt += " appearance";
        }
        txt += " in this article.";
        return txt;
    },
    render: function() {
        if (this.inPopover() && (this.props.reference.mentions === 1)) {
            return <div>Appears once in this article.</div>;
        } else {
            return <Revealable revealText={ this.appearanceText() }>
                <ReferenceAppearanceList reference={ this.props.reference } currentMention={ this.props.currentMention }/>
                </Revealable>;
        }
    }
});

/**
 * A list of appearances for a given reference in a paper.
 */
var ReferenceAppearanceList = React.createClass({
    render: function() {
        var ref = this.props.reference;
        /* generate an index (count) for each citation group; e.g., the 2nd citation of a given reference in the document */
        var citationGroupsWithIndex = _.map(ref.citation_groups, function (group, index) {
            group['index'] = index;
            return group;
        });
        /* group each citation group by the section it is in */
        var citationGroupsBySection = _.groupBy(citationGroupsWithIndex, function(g) { return g.section; });
        return _.map(citationGroupsBySection, function(value, key) {
            var mentions = _.map(value, function (mention) {
                if (this.props.currentMention === mention.index) {
                    return <div key={ "mention" + mention.word_position } ><dt>☛</dt><dd>{ mention.context }</dd></div>;
                } else {
                    return <div key={ "mention" + mention.word_position } >
                        <dt></dt><dd><a href={ "#ref_" + ref.id + "_" + mention.index } >{ mention.context }</a></dd>
                        </div>;
                }
            }.bind(this));
            return <div key={ "appearance_list_" + ref.id + "-" + key } ><p><strong>{ key }</strong></p>
                <dl className="appearances">{ mentions }</dl>
                </div>;
        }.bind(this));
    }
});
                                                
var ReferenceAuthorList = React.createClass({
    getInitialState: function() {
        return { expanded: false };
    },
    handleClick: function() {
        this.setState({ expanded: !this.state.expanded});
        return false;
    },
    render: function() {
        /* display at most 4 authors; if > than 4, display first 3 then et al */
        var etal = "";
        var authorMax = 3;
        if (this.props.authors.length > (authorMax + 1) && !this.state.expanded) {
            etal = <span>, (<a href="#" onClick={ this.handleClick }>and { this.props.authors.length - authorMax } more</a>)</span>;
        } else {
            authorMax = this.props.authors.length;
        }
        var authorString = _.map(this.props.authors.slice(0, authorMax), formatAuthorNameInvertedInitials).join(", ");
        return <span className="reference-authors">{ authorString }{ etal }</span>;
    }
});

var ReferenceActionList = React.createClass({
    render: function() {
        var ref = this.props.reference;
        var actionListId = ref.id + "action-list";
        setTimeout(function () {
            $(jq(actionListId)).hide();
            $(jq('reference_' + ref.id)).hover(
                function () {
                    $(jq(actionListId)).fadeIn();
                }, 
                function () {
                    $(jq(actionListId)).fadeOut();
                });
        }.bind(this), 1);
        return <div id={ actionListId } className="action-list">
                Download reference (<a href={ "/references/" + encodeURIComponent(ref.info.doi) + "?format=bib" }>BibTeX</a>)
            (<a href={ "/references/" + encodeURIComponent(ref.info.doi) + "?format=ris" }>RIS</a>)<br/>
                </div>;
    }
});

var Reference = React.createClass({
    getInitialState: function() {
        return { authorsExpanded: false };
    },
    getDefaultProps: function() {
        return { currentMention: null };
    },
    isPopover: function() {
        return (this.props.currentMention !== null);
    },
    componentDidUpdate: function() {
        if (this.props.qtip) {
            this.props.qtip.reposition();
        }
    },
    componentDidMount: function() {
        if (this.props.qtip) {
            this.props.qtip.reposition();
        }
    }, 
    isSelected: function () {
        return ($.param.fragment() === this.props.reference.id);
    },
    renderLabel: function() {
        if (this.props.showLabel) {
            /* check if this is the selected anchor */
            var ref = this.props.reference;
            if (this.isSelected()) {
                return <span className="label"><a href="#" onClick={ function() { window.history.back(); return false; } }>{ ref.index }</a>.</span>;
            } else {
                return <span className="label">{ ref.index }.</span>;
            }
        } else {
            return "";
        }
    },
    renderTitle: function(info) {
        if (info.doi) {
            return <span className="reference-title"><a className="reference-link" href={ "http://dx.doi.org/" + info.doi }>{ info.title }</a><br/></span>;
        } else {
            return <span className="reference-title">{ info.title }<br/></span>;
        }
    },
    renderReference: function (ref) {
        var info = ref.info;
        if (info.title) {
                return <span><a id={ ref.id } name={ this.props.id }></a>
                <span title={ ref.text }><ReferenceAuthorList authors={ info.author || [] }/> ({ info.issued && info.issued['date-parts'][0][0] })</span><br/>
                { this.renderTitle(info) }
                <span className="reference-journal">{ info['container-title'] }</span><br/>
                <Maybe test={ this.props.reference.info }>
                  <span className="reference-doi">{ info.doi }<br/></span>
                </Maybe>
                <Maybe test={ !this.isPopover() && ref.info.doi }>
                  <ReferenceActionList reference={ ref }/>
                </Maybe>
                </span>;

        } else {
            return <span dangerouslySetInnerHTML={ {__html: ref.html} } />;
        }
    },
    render: function () {
        var className = "reference";
        if (this.isSelected()) { className = className + " selected"; }
        return <div id={ 'reference_' + this.props.reference.id } className={ className }>
            { this.renderLabel() } { this.renderReference(this.props.reference) }
            <Maybe test={ this.props.reference.self_citations }>
              <span className="selfcitation">Self-citation</span>
            </Maybe>
            <ReferenceUpdated updated_by={ this.props.reference.updated_by }/>
            <ReferenceAbstract text={ this.props.reference.info.abstract }/>
            <ReferenceAppearanceList reference={ this.props.reference } currentMention={ this.props.currentMention }/>
            </div>;
    }
});

var ReferenceUpdated = React.createClass({
    render: function () {
        if (this.props.updated_by) {
            var types = _.map(this.props.updated_by, function(u) { return u.type; });
            if (_.contains(types, "retraction")) {
                return <span className="retracted">RETRACTED</span>;
            } else if (types.length > 0) {
                return <span className="updated">UPDATED</span>;
            } else {
                return <span/>;
            }
        } else {
            return <span/>;
        }
    }
});

/**
 * Function to make a function to return the appropriate heading for a
 * reference given a sortby string (e.g., appearance)
 */
function mkHeadingGrouper(by) {
    return function (ref) {
        /* handle reference groups */
        if ($.type(ref) === 'array') {
            ref = ref[0];
        }
        if (by === "journal") {
            return ref.data.info['container-title'];
        } else if (by === "appearance" || by === "appearance+repeated") {
            return ref.group.section;
        } else {
            return null;
        }
    };
}

var SortedReferencesList = React.createClass({
    useHeadings: function() {
        return ["journal","appearance"].indexOf(this.props.current.by) !== -1;
    },
    renderGroupContext: function(group) {
        if (this.props.showCitationContext) {
            return <p>{ group[0].group.context }</p>;
        } else {
            return "";
        }
    },
    renderReferenceList: function(refs) {
        if ($.type(refs) === 'array') {
            if ($.type(refs[0]) === 'array') {
                /* grouped citations */
                return _.map(refs, function (group) {
                    var key = "citation_group_" + group[0].group.word_position;
                    return <div className="citationGroup" key={ key }>
                        { this.renderGroupContext(group) }
                        { this.renderReferenceList(group) }
                    </div>;
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
                var allTokens = $.unique(tokens.concat(this.props.idx.pipeline.run(tokens)));
                $("ol.references").highlight(allTokens);
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
            var grouper = mkHeadingGrouper(this.props.current.by);
            sorted = _.groupBy(sorted, grouper);
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

/**
 * Form used for filtering references.
 */
var SearchBar = React.createClass({
    render: function() {
        return (
            <form onSubmit={function(){return false;}}>
                <input
                    type="text"
                    placeholder="Search..."
                    value={ this.props.filterText }
                    onChange={ function(event) { this.props.onSearchUpdate(event.target.value); }.bind(this) } />
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
        var isCurrent = (this.props.current.by === this.props.by);
        if (!this.props.toggleable && isCurrent) {
            return <span>{this.props.name}</span>;
        } else {
            var orderStr = "";
            if (this.props.toggleable && isCurrent) {
                orderStr = (this.props.current.order === "asc") ? "↑ " : "↓ ";
            }
            return <button onClick={this.handleClick}>{orderStr}{this.props.name}</button>;
        }
    }
});

/**
 * Class containing a reference in a popover.
 */
var ReferencePopover = React.createClass({
    render: function() {
        var references = _.map(_.zip(this.props.references, this.props.currentMentions), function(d) {
            return <Reference
              reference={ d[0] }
              qtip={ this.props.qtip }
              key={ d[0].id }
              showLabel={ this.props.references.length > 1 }
              currentMention={ d[1] } />;
        }.bind(this));
        return <div>{ references }</div>;
var Toggle = React.createClass({
    getDefaultProps: function() {
        return {
            available: true
        };
    },
    handleClick: function() {
        this.props.onClick();
        return false;
    },
    render: function () {
        var toggle = this.props.toggleState ? "☑" : "☐";
        return <p className="toggle"><button className="non-button" onClick={ this.handleClick } disabled={ !this.props.available }>{ toggle } { this.props.children }</button></p>;
    }
});

    }
});
        
var ReferencesApp = React.createClass({
    getInitialState: function() {
        return {sort: { by: "appearance", order: "asc" },
                filterText: '',
                showRepeated: false,
                groupCitations: false,
                showCitationContext: false};
    },
    componentWillMount: function() {
        $(citationSelector).filter(citationFilter).on( "click", function() {
            this.setState({ filterText: "" });
        }.bind(this));
    },
    componentWillMount: function() {
        /* build full-text index */
        this.idx = buildIndex(this.props.references);
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
    toggleShowRepeated: function() {
        this.setState({showRepeated: !this.state.showRepeated});
        return false;
    },
    toggleGroupCitations: function() {
        this.setState({groupCitations: !this.state.groupCitations});
        return false;
    },
    toggleShowCitationContext: function() {
        this.setState({showCitationContext: !this.state.showCitationContext});
        return false;
    },
    render: function() {
        var showRepeatedAvailable = (this.state.sort.by === 'appearance');
        var groupCitationsAvailable = showRepeatedAvailable && this.state.showRepeated;
        var showCitationContextAvailable = groupCitationsAvailable && this.state.groupCitations;
        return <div>
            <SearchBar filterText={this.state.filterText} onSearchUpdate={this.handleSearchUpdate}/>
            <div className="sorter">
            <strong>Sort by:</strong>
            <ul className="sorters">
            <li><Sorter name="Order in paper"    by="appearance"    current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Title"    by="title"    current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Author"   by="author"   current={this.state.sort} onClick={this.handleSorterClick}/> | </li>
            <li><Sorter name="Year"     by="year"     current={this.state.sort} onClick={this.handleSorterClick} defaultOrder="desc" toggleable={ true } /> | </li>
            <li><Sorter name="Appearances" by="mentions" current={this.state.sort} onClick={this.handleSorterClick} defaultOrder="desc"/> | </li>
            <li><Sorter name="Journal"  by="journal"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            </div>
            <div>
              <Toggle onClick={ this.toggleShowRepeated } toggleState={ this.state.showRepeated } available= { showRepeatedAvailable }>
                Show repeated citations
              </Toggle>
            <Toggle onClick={ this.toggleGroupCitations } toggleState={ this.state.groupCitations } available={ groupCitationsAvailable }>
                Group citations
              </Toggle>
              <Toggle onClick={ this.toggleShowCitationContext } toggleState={ this.state.showCitationContext } available={ showCitationContextAvailable }>
                Show citation context
              </Toggle>
            </div>
            <SortedReferencesList
              current={this.state.sort}
              references={this.props.references}
              filterText={this.state.filterText}
              idx={ this.idx }
              searchResultsFilter={mkSearchResultsFilter(this.idx, this.state.filterText)}
              showRepeated={ this.state.showRepeated }
              groupCitations={ this.state.groupCitations }
              showCitationContext={ this.state.showCitationContext }
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
function mkReferencePopover(id, references, currentMentions) {
    var popoverId = guid();
    $(jq(id)).qtip({
        content: {
            text: function(event, api) {
                setTimeout(function (){
                    React.renderComponent(<ReferencePopover references={ references } qtip={ api } currentMentions={ currentMentions }/>,
                                          $(jq(popoverId)).get(0));
                }.bind(this), 1);
                return "<div id='" + popoverId + "'>Loading...</div>";
            }
        },
        hide: {
            fixed: true,
            delay: 1000
        },
        style: { classes: 'citation-popover' },
        position: {
            viewport: $(window),
            adjust: {
                method: 'shift shift'
            }
        }
    });
}

/**
 * Functions to manage citation refernce ids. Of the form ref_ID_COUNT.
 * 
 */
function extractCitationReferenceInfo(id) {
    var md = id.match(/^ref_([^_]+)_([0-9])+$/);
    return (md && {id: md[1], count: parseInt(md[2])}) || null;
}

function generateCitationReferenceId(id, count) {
    return "ref_" + id + "_" + count;
}

function withReferenceData(doi, f) {
    var url = "/papers/" + doi + "?format=json&inline=t";
    $.ajax({ url: url,
             timeout: 300000 // can take a loooong time
           }).done(function(rawdata) {
        f(rawdata);
    });
}

/* if we don't load after document ready we get an error */
$(document).ready(function () {
    /* now fetch the JSON describing the paper */
    withReferenceData(doi, function (data) {
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
                var citationId = generateCitationReferenceId(refId, citationCounters[refId]);
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
                            $("<a id='" + generateCitationReferenceId(refId, citationCounters[refId]) + "'/>").insertAfter(jq(startId));
                        });
                        groupCounter = groupCounter + 1;
                        var spanId = guid();
                        wrapSpan(startId, citationId, spanId);
                        var references = _.map(currentGroupRefIds, function(refId) { return data.references[refId]; });
                        var currentMentions = _.map(currentGroupRefIds, function(refId) { return citationCounters[refId]; });
                        mkReferencePopover(spanId, references, currentMentions);
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
