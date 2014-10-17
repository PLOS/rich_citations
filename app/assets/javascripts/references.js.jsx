/**
  * @jsx React.DOM 
  */

var paper_doi = $('meta[name=citation_doi]').attr("content");

/* local part of the doi */
var paper_doi_local_part = paper_doi && paper_doi.match(/^10.1371\/journal\.(.*)$/)[1];

/* selector that can be used to match all the a elements that are citation links */
var citationSelector = "a[href^='#" + paper_doi_local_part + "']";
var citationFilter = function (el) {
    /* return true for refs that link to a target in the references section */
    return ($("ol.references " + jq($(this).attr("href").substring(1))).length > 0);
};

function getDOI(ref) {
    var bibliographic = ref.bibliographic;
    if (bibliographic.uri_type === 'doi') {
        return bibliographic.uri;
    } else {
        return undefined;
    }
}

function getEncodedDOI(ref) {
    var doi = getDOI(ref);
    if (doi) {
        return encodeURIComponent(doi);
    } else {
        return undefined;
    }
}

function formatAuthorNameInverted (author) {
    if (author.literal) {
        return author.literal;
    } else if (author.given && author.family) {
        return author.family + ", " + author.given;
    } else if (author.family) {
        return author.family;
    } else {
        return "[unknown]";
    }
}

var knownLicenses = {
    'cc-by':                    'read-and-reuse',
    'cc-by-nc-nd':              'read',
    'cc-by-nc-sa':              'read-and-reuse',
    'cc-nc':                    'read-and-reuse',
    'cc-nc-nd':                 'read',
    'cc-nc-sa':                 'read-and-reuse',
    'cc-zero':                  'read-and-reuse',
    'failed-to-obtain-license': 'paywall',
    'free-to-read':             'read',
    'other-closed':             'paywall',
    'other-pd':                 'read-and-reuse',
    'plos-who':                 'read-and-reuse',
    'uk-ogl':                   'read-and-reuse'};

function getLicenseShorthand(ref) {
    if (!ref.bibliographic || !ref.bibliographic.license || typeof(ref.bibliographic.license) !== "string") {
        return knownLicenses["failed-to-obtain-license"];
    } else {
        return knownLicenses[ref.bibliographic.license.toLowerCase()];
    }
}

function getLicenseText(shorthand) {
    if (shorthand === "read") {
        return "Free to read";
    } else if (shorthand === "read-and-reuse") {
        return "Free to read and reuse";
    } else if (shorthand === "paywall") {
        return 'Subscription required or license unknown';
    }
}

function getLicenseSort(ref) {
    var t = getLicenseShorthand(ref);
    if (t === "read-and-reuse") {
        return 0;
    } else if (t === "read") {
        return 50;
    } else {
        return 100;
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
    } else if (author.family) {
        return author.family;
    } else {
        return "[unknown]";
    }
}

/**
 * Build a full-text index from an array of references.
 */
function buildIndex(references) {
    var index = lunr(function () {
        this.field('title', { boost: 10 });
        this.field('author');
        this.field('journal');
        this.field('body');
        this.field('abstract');
    });
    for (var i=0; i<references.length; i++) {
        var ref = references[i];
        var doc = { id: ref.id,
                    author: _.map(ref.bibliographic.author, formatAuthorNameInverted).join(" "),
                    title: ref.bibliographic.title,
                    journal: ref.bibliographic['container-title'],
                    body:  ref.text,
                    abstract: ref.bibliographic['abstract']};
        index.add(doc);
    }
    return index;
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
    var bibliographic = ref.bibliographic;
    if (fieldname === 'appearance') {
        return ref.number;
    } else if (fieldname === 'repeated') {
        /* if no references in paper, sort at end */
        return (ref.citation_groups && ref.citation_groups[0].word_position) || 99999999;
    } else if (fieldname === 'journal') {
        return mkSortString(bibliographic['container-title']);
    } else if (fieldname === 'year') {
        return (bibliographic.issued && bibliographic.issued["date-parts"] && bibliographic.issued["date-parts"][0][0]) || null;
    } else if (fieldname === 'mentions') {
        return ref.citation_groups.length;
    } else if (fieldname === 'author') {
        var first_author = bibliographic.author && bibliographic.author[0];
        return (first_author && mkSortString(formatAuthorNameInverted(first_author))) || null;
    } else if (fieldname === "number") {
        return ref.number;
    } else if (fieldname === 'license') {
        return getLicenseSort(ref);
    } else {
        return null;
    }
}

/**
 * Sorts references by the given fieldname. Returns an object
 * containing two values, sorted and unsortable.
 */
function sortReferences (refs, by) {
    /* data structure to use for sorting */
    var tmp = [];
    if (by === 'repeated') {
        /* special case, show repeated citations in order of appearance */
        tmp = _.chain(refs).map(function(ref) {
            return _.map(ref.citation_groups, function (group) {
                if (!group) {
                    return null;
                } else {
                    return { data: ref,
                             group: group,
                             sort: [group.word_position, ref.number]};
                }
            }.bind(this));
        }).flatten().compact().value();
    } else {
        tmp = _.map(refs, function(ref) {
            return { data: ref,
                     group: (ref.citation_groups && ref.citation_groups[0]) || "References",
                     sort: [mkSortField(ref, by), ref.number] };
        });
    }
    var retval = _.partition(tmp, function (ref) {
        return (ref.sort[0] !== null); // split into sortable, unsortable
    }).map(function(a) {
        return a.sort(arraySorter); // sort both (unsortable will be sorted by number)
    });
    return {sorted:     retval[0],
            unsortable: retval[1]};
}

/**
 * Make a function suitable for filtering a reference list from a
 * given index and a search string.
 */
function mkSearchResultsFilter(index, filterText) {
    var tokens = index.pipeline.run(lunr.tokenizer(filterText));
    if (tokens.length > 0) {
        var resultHash = {};
        index.search(filterText).map(function (res) {
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
    if (!myid) {
        return undefined;
    } else {
        return "#" + myid.replace( /(:|\.|\[|\])/g, "\\$1" );
    }
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
function buildReferenceData(json) {
    var retval = {};
    $.each(json.references, function (k, v) {
        retval[v.id] = v;
        var html = $(jq(v.id)).parent().first().remove("span.label").html();
        // cannot get this to work properly in jquery
        html = html.replace(/<span class="label">[^<]+<\/span>/, '');
        retval[v.id]['html'] = html;
        retval[v.id]['text'] = $(jq(v.id)).parent().first().text();
        retval[v.id]['citation_groups'] = _.map(v.citation_groups,
                                             function (id) {
                                                 return json.citation_groups[id];
                                             });
        retval[v.id]['mentions'] = v.citation_groups.length;
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
    render: function() {
            return <Maybe test={ this.props.text }>
                     <Revealable qtip={ this.props.qtip} revealText={ "Show abstract" }>
                       <p className="abstract">{ this.props.text }</p>
                     </Revealable>
                   </Maybe>;
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
    componentDidUpdate: function() {
        this.props.qtip && this.props.qtip.reposition();
    },
    componentDidMount: function() {
        this.props.qtip && this.props.qtip.reposition();
    }, 
    handleClick: function() {
        this.setState({ show: !this.state.show });
        return false;
    },
    render: function() {
        return <div className="appearance-toggle"><button className="non-button" onClick={ this.handleClick }>
            { this.state.show ? "▾" : "▸" } { this.props.revealText}</button>
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
        if (this.props.reference.zero_mentions) {
            return <div>Does not appear in the article text.</div>;
        } else if (this.inPopover() && (this.props.reference.mentions === 1)) {
            return <div>Appears once in this article.</div>;
        } else {
            return <Revealable qtip={ this.props.qtip } revealText={ this.appearanceText() }>
                <ReferenceAppearanceList reference={ this.props.reference } currentMention={ this.props.currentMention }/>
                </Revealable>;
        }
    }
});

var MentionContext = React.createClass({
    render: function() {
        var context = this.props.context;
        return <span>{ context.ellipses_before }{ context.text_before }<b>{ context.citation }</b>{ context.text_after }{ context.ellipses_after }</span>;
    }
});
    
/**
 * A list of appearances for a given reference in a paper.
 */
var ReferenceAppearanceList = React.createClass({
    renderMention: function(mention) {
        var ref = this.props.reference;
        if (this.props.currentMention === mention.number) {
            return <div key={ "mention" + mention.word_position } ><dt>▸</dt><dd><MentionContext context={ mention.context }/></dd></div>;
        } else {
            return <div key={ "mention" + mention.word_position } >
                <dt></dt><dd><a href={ "#ref_" + ref.id + "_" + mention.number } ><MentionContext context={ mention.context }/></a></dd>
                </div>;
        }
    },
    render: function() {
        var ref = this.props.reference;
        /* generate an index (count) for each citation group; e.g., the 2nd citation of a given reference in the document */
        var citationGroupsWithIndex = _.map(ref.citation_groups, function (group, index) {
            group['index'] = index;
            return group;
        });
        /* group each citation group by the section it is in */
        var citationGroupsBySection = _.groupBy(citationGroupsWithIndex, function(g) { return g.section; });
        var t = _.map(citationGroupsBySection, function(value, key) {
            return <div key={ "appearance_list_" + ref.id + "-" + key } ><p><strong>{ key }</strong></p>
                <dl className="appearances">{ _.map(value, this.renderMention) }</dl>
                </div>;
        }.bind(this));
        return <div>{ t }</div>;
    }
});

/**
 * Class to manage an expandable list of authors.
 */
var ReferenceAuthorList = React.createClass({
    getInitialState: function() {
        return { expanded: false };
    },
    handleClick: function() {
        this.setState({ expanded: !this.state.expanded});
        if (this.props.updateHighlighting) { this.props.updateHighlighting(); }
        return false;
    },
    render: function() {
        /* display at most authorMax + 1 authors; if > than authorMax + 1, display authorMax then et al */
        var etal = "";
        var authorMax = this.props.authorMax;
        var authors = this.props.authors || [];
        if (authors.length > (authorMax + 1) && !this.state.expanded) {
            etal = <span>, (<a href="#" onClick={ this.handleClick }>and { authors.length - authorMax } more</a>)</span>;
        } else {
            authorMax = authors.length;
        }
        var authorString = _.map(authors.slice(0, authorMax), formatAuthorNameInvertedInitials).join(", ");
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
            Download reference (<a href={ "/references/" + getEncodedDOI(ref) + "?format=bib" }>BibTeX</a>)
            (<a href={ "/references/" + getEncodedDOI(ref) + "?format=ris" }>RIS</a>)<br/>
                </div>;
    }
});

var Reference = React.createClass({
    getDefaultProps: function() {
        return { currentMention: null };
    },
    isPopover: function() {
        return (this.props.currentMention !== null);
    },
    renderLabel: function() {
        if (this.props.showLabel) {
            /* check if this is the selected anchor */
            var ref = this.props.reference;
            if (this.props.selected) {
                return <span className="label"><a href="#" onClick={ function() { window.history.back(); return false; } }>↩{ ref.number }</a>.</span>;
            } else {
                return <span className="label">{ ref.number }.</span>;
            }
        } else {
            return <span/>;
        }
    },
    render: function () {
        var className = "reference";
        if (this.props.selected) {
            className = className + " selected";
        }
        return <div id={ 'reference_' + this.props.reference.id } className={ className }>
            { this.renderLabel() }
            <CrossmarkBadge reference={ this.props.reference }/>
            <ReferenceCore reference={ this.props.reference } isPopover={ this.isPopover() }
                           suppressJournal={ this.props.suppressJournal }
                           updateHighlighting={ this.props.updateHighlighting }
            />
            <Maybe test={ !this.props.suppressLicenseBadge }>
              <LicenseBadge reference={ this.props.reference }/>
            </Maybe>
            <Maybe test={ this.props.reference.self_citations }>
              <span key={ this.props.reference.id + "selfcitation" } className="selfcitation">Self-citation</span><br/>
            </Maybe>
            <ReferenceAbstract text={ this.props.reference.bibliographic.abstract } qtip={ this.props.qtip }/>
            <ReferenceAppearanceListRevealable reference={ this.props.reference } currentMention={ this.props.currentMention } qtip={ this.props.qtip }/>
            </div>;
    }
});

var ReferenceCore = React.createClass({
    render: function () {
        var ref = this.props.reference;
        var bibliographic = ref.bibliographic;
        var doi = getDOI(ref);
        if (bibliographic.title) {
            var id = "";
            if (!this.props.isPopover) {
                id = ref.id + "_title";
                setTimeout(function (){
                    $(jq(id)).qtip({
                        content: {
                            text: function(event, api) {
                                return "<div>Original text: " + ref.text + "</div>";
                            }
                        },
                        hide: {
                            fixed: true,
                            delay: 100
                        },
                        style: { classes: 'citation-popover' },
                        position: {
                            viewport: $(window),
                            adjust: {
                                method: 'shift shift'
                            }
                        }
                    });
                }, 1000);
            }
            return <span><a id={ ref.id } name={ this.props.id }></a>
                <span id={ id }>
                <ReferenceAuthorList authorMax={ this.props.isPopover ? 3 : 5 } updateHighlighting={ this.props.updateHighlighting } authors={ bibliographic.author }/>
                { bibliographic.issued && bibliographic.issued['date-parts'] && " (" + bibliographic.issued['date-parts'][0][0] + ")" }
                </span><br/>
                <ReferencePublicationInfo reference={ ref } suppressJournal={ this.props.suppressJournal } isPopover={ this.props.isPopover }/>
                </span>;

        } else {
            return <span dangerouslySetInnerHTML={ {__html: ref.html} } />;
        }
    }
});

var ReferencePublicationInfo = React.createClass({
    render: function() {
        var t = this.props.reference.bibliographic['type'];
        if (t === 'book') {
            return <ReferencePublicationInfoBook reference={ this.props.reference } />;
        } else {
            return <ReferencePublicationInfoGeneric reference={ this.props.reference } isPopover={ this.props.isPopover } suppressJournal={ this.props.suppressJournal }/>;
        }
    }
});
                
var ReferencePublicationInfoGeneric = React.createClass({
    renderTitle: function(ref) {
        var bibliographic = ref.bibliographic;
        var encodedDOI = getEncodedDOI(ref);
        if (encodedDOI) {
            var url = "/interstitial?from=" + encodeURIComponent(paper_doi) + "&to=" + ref.number;
            return <span className="reference-title"><a target="_blank" className="reference-link" href={ url } dangerouslySetInnerHTML={{ __html: bibliographic.title }} /><br/></span>;
        } else {
            return <span><span className="reference-title" dangerouslySetInnerHTML={{ __html:bibliographic.title }} /><br/></span>;
        }
    },
    render: function() {
        var ref = this.props.reference;
        var bibliographic = ref.bibliographic;
        var doi = getDOI(ref);
        return <span>
            { this.renderTitle(ref) }
            <Maybe test={ bibliographic['container-title'] && !this.props.suppressJournal }>
            <span className="reference-journal">{ bibliographic['container-title'] }</span>
            <Maybe test={ !doi && (bibliographic['volume'] || bibliographic['issue'] || bibliographic['issued']) }>
            <span> { bibliographic['volume'] }<Maybe test={ bibliographic['issue'] }><span>({ bibliographic['issue'] })</span></Maybe><Maybe test={ bibliographic['page'] }>: { bibliographic['page'] }</Maybe></span>
                  </Maybe>
            <br/>
            </Maybe>
                <Maybe test={ !this.props.isPopover && doi }>
                  <ReferenceActionList reference={ ref }/>
            </Maybe>
            </span>;
    }
});

/**
 * Extract the year OR the literal value from a citeproc-json formatted date.
 */
function getYearOrLiteral(d) {
    if (!d) {
        return null;
    } else {
        if (d['date-parts']) {
            return d['date-parts'][0][0];
        } else if (d['literal']) {
            return d['literal'];
        } else {
            return null;
        }
    }
}
            
var ReferencePublicationInfoBook = React.createClass({
    render: function() {
        var ref = this.props.reference;
        var bibliographic = ref.bibliographic;
        var doi = getDOI(ref);
        var place = bibliographic['place'];
        var publisher = bibliographic['publisher'];
        var issued = bibliographic['issued'];
        var year = getYearOrLiteral(bibliographic['issued']);
        return <span>
            <span className="reference-journal">{ bibliographic['title'] }</span><br/>
            <Maybe test={ place }>
              <span>{ place }</span>
            </Maybe>
            <Maybe test={ place && publisher }>: </Maybe>
            <Maybe test={ publisher }>
            { publisher }
            </Maybe>
            <Maybe test={ (place || publisher) && year }>
            <span>, </span>
            </Maybe>
            { year }
            </span>;
    }
});

var CrossmarkBadge = React.createClass({
    render: function() {
        var ref = this.props.reference;
        if (this.props.reference.updated_by) {
            var types = _.map(this.props.reference.updated_by, function(u) { return u.type; });
            if (_.contains(types, "retraction")) {
                return <span key={ ref.id + "retracted"} className="retracted">RETRACTED<br/></span>;
            } else if (types.length > 0) {
                return <span key={ ref.id + "retracted"} className="updated">UPDATED<br/></span>;
            }
        }
        return <span/>;
    }
});
                                      
var LicenseBadge = React.createClass({
    render: function() {
        var ref = this.props.reference;
        var license = getLicenseShorthand(ref);
        if (license === "read") {
            return <span key={ ref.id + "license" } className="text-available">● { getLicenseText(license) }<br/></span>;
        } else if (license === "read-and-reuse") {
            return <span key={ ref.id + "license" } className="open-access">● { getLicenseText(license) }<br/></span>;
        }
        return <span/>;
    }
});

/**
 * Function to make a function to return the appropriate heading for a
 * reference given a sortby string (e.g., appearance)
 */
function mkHeadingGrouper(by) {
    var last = null;
    return function (ref) {
        /* handle reference groups */
        if ($.type(ref) === 'array') {
            ref = ref[0];
        }
        if (by === "journal") {
            return ref.data.bibliographic['container-title'];
        } else if (by === "appearance" || by === "repeated") {
            if (ref.group.section) {
                /* hack to handle the fact that sometimes we have no
                 * group, for unmentioned cites. Use the last one. */
                last = ref.group.section;
            }
            return ref.group.section || last;
        } else if (by === "license") {
            return getLicenseShorthand(ref.data);
        } else {
            return null;
        }
    };
}

var SortedReferencesList = React.createClass({
    useHeadings: function() {
        return ["journal","appearance","repeated","license"].indexOf(this.props.current.by) !== -1;
    },
    renderGroupContext: function(group) {
        if (this.props.current.by === "repeated") {
            return <p><MentionContext context={ group[0].group.context }/></p>;
        } else {
            return "";
        }
    },
    renderGroupHeading: function(key) {
        if (this.props.current.by === "license") {
            if (key === "read") {
                return <p><span className="text-available">● { getLicenseText(key) }</span></p>;
            } else if (key === "read-and-reuse") {
                return <p><span className="open-access">● { getLicenseText(key) }</span></p>;
            } else {
                return <p><span className="paywalled">● { getLicenseText(key) }</span></p>;
            }
        } else {
            return <p><strong>{ key }</strong></p>;
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
                    { this.renderGroupHeading(key) }
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
                var allTokens = $.unique(tokens.concat(this.props.number.pipeline.run(tokens)));
                $("ol.references").highlight(allTokens);
            }.bind(this), 1);
        }
    },
    renderReferenceItem: function(ref) {
        /* Build elements for react */
        var selected = (this.props.current.by !== 'repeated') &&
                ($.param.fragment() === ref.data.id);
        return <li key={ "" + ref.data.id + ref.group.word_position }>
            <Reference reference={ ref.data }
                       selected = { selected }
                       showLabel={ true }
                       suppressLicenseBadge={ this.props.current.by === "license" }
                       updateHighlighting={ this.updateHighlighting }
                       suppressJournal={ this.props.current.by === "journal" }/>
            </li>;
    },
    renderSortedReferenceList: function (sorted) {
        if (this.props.current.order == "desc") {
            sorted = sorted.reverse();
        }
        if (this.props.current.by === "repeated") {
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
        var results = sortReferences(filtered, this.props.current.by);
        this.updateHighlighting();

        return <div>
            <SortedHeader onClick={ this.props.onClick } current={ this.props.current } unsortableCount={ results.unsortable.length }/>
            { this.renderSortedReferenceList(results.sorted) }
            { (results.sorted.length === 0 && results.unsortable.length === 0) ? <div>No results found.</div> : "" }
            { (results.unsortable.length > 0 ) ? <h5 id="unsortable">Unsortable</h5> : ""}
            <ol className="references">{ results.unsortable.map(this.renderReferenceItem) }</ol>
            </div>;
    }
});

var SortedHeader = React.createClass({
    handleClick: function() {
        var newOrder = "asc";
        if (this.props.current.order === "asc") { newOrder = "desc"; }
        this.props.onClick(this.props.current.by, newOrder);
        return false;
    },
    render: function() {
        if (this.props.current.by === 'year') {
            if (this.props.current.order === 'desc') {
                return <p><a href="#" onClick={ this.handleClick }>Newest first ▾</a> <Unsortable count={ this.props.unsortableCount } current={ this.props.current }/></p>;
            } else {
                return <p><a href="#" onClick={ this.handleClick }>Oldest first ▴</a> <Unsortable count={ this.props.unsortableCount } current={ this.props.current }/></p>;
            }                
        } else {
            return <p><Unsortable count={ this.props.unsortableCount } current={ this.props.current }/></p>;
        }
    }
});

var Unsortable = React.createClass({
    render: function() {
        if (this.props.count > 0) {
            if (this.props.current.by === 'year') {
                return <span>(<a href="#unsortable">{ this.props.count } unknown date{ (this.props.count > 1) ? "s" : "" }</a>)</span>;
            } else if (this.props.current.by === 'author') {
                return <span>Alphabetical (<a href="#unsortable">{ this.props.count } unsortable</a>)</span>;
            } else { 
                return <span><a href="#unsortable">{ this.props.count } unsortable</a></span>;
            }
        } else {
            return <span/>;
        }
    }
});

/**
 * Form used for filtering references.
 */
var SearchBar = React.createClass({
    render: function() {
        return (
            <form className="search" onSubmit={function(){return false;}}>
                <input
                    type="text"
                    placeholder="Search..."
                    value={ this.props.filterText }
                    name="referencefilter"
                    onChange={ function(event) { this.props.onSearchUpdate(event.target.value); }.bind(this) } />
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
        var isCurrent = (this.props.current.by === this.props.by);
        if (isCurrent) {
            return <span><strong>{ this.props.children }</strong></span>;
        } else {
            return <button className="non-button" onClick={ this.handleClick }>{ this.props.children }</button>;
        }
    }
});

/**
 * Class containing a reference in a popover.
 */
var ReferencePopover = React.createClass({
    componentDidMount: function() {
        this.props.qtip && this.props.qtip.reposition();
    }, 
    render: function() {
        var references = _.map(_.zip(this.props.references, this.props.currentMentions), function(d) {
            return <Reference
              selected={ false }
              reference={ d[0] }
              qtip={ this.props.qtip }
              key={ d[0].id }
              showLabel={ this.props.references.length > 1 }
              currentMention={ d[1] } />;
        }.bind(this));
        return <div>{ references }</div>;
    }
});

var ReferencesApp = React.createClass({
    getInitialState: function() {
        return {sort: { by: "appearance", order: "asc" },
                filterText: ''};
    },
    componentWillMount: function() {
        /* build full-text index */
        this.number = buildIndex(this.props.references);
    },
    componentDidMount: function() {
        $(citationSelector).filter(citationFilter).on( "click", function() {
            this.setState({ filterText: "" });
        }.bind(this));
        $(window).bind('hashchange', function(e) {
            /* redraw when the fragment URL changes, to faciliate the link to the back button */
            this.setState({});
            /* fix scroll for top bar */
            $(window).scrollFrame();
        }.bind(this));
    },
    handleSearchUpdate: function(filterText) {
        this.setState({ filterText: filterText });
    },
    handleSorterClick: function(by, order) {
        this.setState({sort: { by: by, order: order }});
    },
    render: function() {
        return <div>
            <div className="sorter">
            <strong>Sort by:</strong>
            <ul className="sorters">
            <li><Sorter by="appearance" current={ this.state.sort } onClick={ this.handleSorterClick }>Order in paper</Sorter> | </li>
            <li><Sorter by="repeated"   current={ this.state.sort } onClick={ this.handleSorterClick }>Citation groups</Sorter> | </li>
            <li><Sorter by="author"     current={ this.state.sort } onClick={ this.handleSorterClick }>Author</Sorter> | </li>
            <li><Sorter by="year"       current={ this.state.sort } onClick={ this.handleSorterClick } defaultOrder="desc" toggleable={ true } >Year</Sorter> | </li>
            <li><Sorter by="journal"    current={ this.state.sort } onClick={ this.handleSorterClick }>Journal</Sorter> | </li>
            <li><Sorter by="mentions"   current={ this.state.sort } onClick={ this.handleSorterClick } defaultOrder="desc">Number of appearances</Sorter> | </li>
            <li><Sorter by="license"    current={ this.state.sort } onClick={ this.handleSorterClick }>Availability</Sorter></li>
            </ul>
            </div>
            <SearchBar filterText={this.state.filterText} onSearchUpdate={this.handleSearchUpdate}/>
            <SortedReferencesList
              current={this.state.sort}
              references={this.props.references}
              filterText={this.state.filterText}
              onClick={this.handleSorterClick}
              number={ this.number }
              searchResultsFilter={mkSearchResultsFilter(this.number, this.state.filterText)}
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
        $(jq(startId)).wrapAll("<span id='" + spanId + "'/>");
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
            delay: 100
        },
        style: { classes: 'citation-popover' },
        position: {
            viewport: $(window),
            adjust: {
                method: 'shift shift'
            }
        },
        events: {
            visible: function(event, api) {
                $(api.elements.tooltip).css('max-height',$(window).height()*(2/3));
                $(jq(id)).addClass("citation_hover");
            },
            hidden: function(event, api) {
                $(jq(id)).removeClass("citation_hover");
            }
        }
    });
}

/**
 * Iterate over the citations in a document.
 * When a single citation, in a group or not, is found, handleSingle is called with the node and the referenceId.
 * When an elission group is found, e.g. [1]-[3], handleBeginElissionGroup is called with the node [1] and the refid of [1].
 * For each elided reference, e.g. [2] in [1]-[3], handleElided is called with the node [3] and the refId for 2
 * Finally, handleEndElissionGroup is called with the start node [1], the end node [3] and an array of ref ids in the 
 */
function citationIterator(groups, handleSingle, handleBeginElissionGroup, handleElided, handleEndElissionGroup) {
    var groupCounter = 0;
    var inElission = false;
    var inGroupCounter = 0;
    var elissionStart = null;
    var elissionStartRefId = null;

    var citationCounters = {};
    function incCitationCounter(referenceId) {
        if (citationCounters[referenceId] === undefined) {
            citationCounters[referenceId] = 0;
        } else {
            citationCounters[referenceId] = citationCounters[referenceId] + 1;
        }
        return citationCounters[referenceId];
    }
    
    $(citationSelector).filter(citationFilter).each(function() {
        /* get the id of the current reference */
        var refId = $(this).attr('href').substring(1);
        while (!inElission && (refId !== groups[groupCounter].references[inGroupCounter])) {
            /* we have a citation group in the JSON that does not
             * exist in the HTML ; possibly a table? */
            /* skip over the rest, incrementing the counters while we do so */
            var currentGroupRefIds = groups[groupCounter].references;
            while (inGroupCounter < currentGroupRefIds.length) {
                incCitationCounter(currentGroupRefIds[inGroupCounter]);
                inGroupCounter = inGroupCounter + 1;
            }
            inGroupCounter = 0;
            groupCounter = groupCounter + 1;
        }
        incCitationCounter(refId);
        /* the list of reference id for the current citation group */
        var currentGroupRefIds = groups[groupCounter].references;
        if (currentGroupRefIds.length === 1) {
            if (refId === currentGroupRefIds[0]) {
                /* single group, no anchors to add */
                groupCounter = groupCounter + 1;
                if (handleSingle) {
                    handleSingle(this, refId, citationCounters[refId]);
                }
            } else {
                console.log("Problem in group " + groupCounter + " with ref " + inGroupCounter);
                console.log("Found " + refId + ", expected " + currentGroupRefIds[inGroupCounter]);
                console.log(groups[groupCounter]);
            }
        } else {
            if (inElission) {
                /* advance the inGroupCounter until we reach the end of the elission group */
                var cites = [elissionStartRefId];
                while (refId !== currentGroupRefIds[inGroupCounter]) {
                    if (inGroupCounter >= currentGroupRefIds.length) {
                        /* something is wrong, we've gone too far */
                        console.log("Unable to find end of ellission group: " + currentGroupRefIds);
                        break;
                    }
                    var erefId = currentGroupRefIds[inGroupCounter];
                    incCitationCounter(erefId);
                    if (handleElided) {
                        handleElided(this, erefId, citationCounters[erefId]);
                    }
                    cites.push(currentGroupRefIds[inGroupCounter]);
                    inGroupCounter = inGroupCounter + 1;
                }
                cites.push(refId);
                if (handleEndElissionGroup) {
                    var counters = _.map(cites, function(c) { return citationCounters[c];});
                    handleEndElissionGroup(elissionStart, this, cites, counters);
                }
                inElission = false;
                elissionStart = null;
                elissionStartRefId = null;
            } else {
                if (refId === currentGroupRefIds[inGroupCounter]) {
                    /* check to see if the next ref is elided or if we are at the end */
                    var next = $(this).next(citationSelector).filter(citationFilter);
                    var nextRefId = ($(next).length > 0) && $(next).attr('href').substring(1);
                    if (!nextRefId ||
                        (inGroupCounter == (currentGroupRefIds.length-1)) // last citation in group
                        || (nextRefId === currentGroupRefIds[inGroupCounter + 1])) { // next ref is in group
                        /* not an elission */
                        if (handleSingle) {
                            handleSingle(this, refId, citationCounters[refId]);
                        }
                    } else {
                        /* elission starts here */
                        if (handleBeginElissionGroup) {
                            handleBeginElissionGroup(this, refId, citationCounters[refId]);
                        }
                        inElission = true;
                        elissionStart = this;
                        elissionStartRefId = refId;
                    }
                } else {
                    console.log("Problem in group " + groupCounter + " with ref " + inGroupCounter);
                    console.log("Found " + refId + ", expected " + currentGroupRefIds[inGroupCounter]);
                    console.log(groups[groupCounter]);
                }
            }
            inGroupCounter = inGroupCounter + 1;
            if (refId === currentGroupRefIds[currentGroupRefIds.length-1]) {
                /* at end, advance group counter and reset inGroupCounter */
                inGroupCounter = 0;
                groupCounter = groupCounter + 1;
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
             statusCode: {
                 201: function() {
                     setTimeout(function () {
                         withReferenceData(doi, f);
                     }, 2000);
                 },
                 200: function(rawdata) {
                     if (!rawdata.failed) {
                         f(rawdata);
                     }
                 }
             }
           });
}

function redirectOnce(to) {
    var key = 'redirected_' + to;
    if (!localStorage.getItem(key)) {
        window.setTimeout(function() {
            localStorage.setItem(key, true);
            window.location.href = to;
        }, 1);
    }
}

/** 
 * Add custom ids to each citation.
 */
function addCitationIds(groups) {
    /* track the current count for each citation */
    function handleSingle(node, refId, c) {
        /* give this a unique id */
        $(node).attr("id", generateCitationReferenceId(refId, c));
    }
    function handleElided(node, refId, c) {
        $("<a id='" + generateCitationReferenceId(refId, c) + "'/>").insertAfter($(node));
    }
    function handleBeginElissionGroup(node, refId, c) {
        $(node).attr("id", generateCitationReferenceId(refId, c));
    }
    function handleEndElissionGroup(start, end, refIds, counters) {
        $(end).attr("id", generateCitationReferenceId(refIds[refIds.length-1], counters[counters.length-1]));
    }
    citationIterator(groups, handleSingle, handleBeginElissionGroup, handleElided, handleEndElissionGroup);
}

function mkPopovers(data) {
    function handleSingle(node, refId, c) {
        mkReferencePopover($(node).attr('id'), [data.references[refId]], [c]);
    }
    function handleEndElissionGroup(start, end, refIds, counters) {
        var spanId = guid();
        wrapSpan($(start).attr('id'), $(end).attr('id'), spanId);
        var references = _.map(refIds, function(refId) { return data.references[refId]; });
        mkReferencePopover(spanId, references, counters);
    }
    citationIterator(data.citation_groups, handleSingle, null, null, handleEndElissionGroup);
}

/* if we don't load after document ready we get an error */
$(document).ready(function () {
    /* now fetch the JSON describing the paper */
    if (paper_doi) {
        /* insert the container */
        $("<div id='richcites'>Loading rich citations <img src='" + spinnerPath + "'/></div>").insertBefore("#references");
        $("<div id='loader2'><img src='" + spinnerPath + "'/></div>").insertAfter($("#nav-article-page ul").first());
        withReferenceData(paper_doi, function (data) {
            try {
                var references = buildReferenceData(data);
                console.log(references);
                /* and drop into react */
                React.renderComponent(
                        <ReferencesApp references={references} />,
                    $("ol.references").get(0)
                );
                addCitationIds(data.citation_groups);
                mkPopovers(data);
                $("#richcites").replaceWith("<div id='richcites'>Rich Citations Engaged!</div>");
                $("#loader2").replaceWith("<div id='loader2'></div>");
            } catch (err) {
                console.log(err);
                $("#richcites").replaceWith("<div id='richcites'>Error loading Rich Citations!</div>");
                $("#loader2").replaceWith("<div id='richcites'></div>");
            }
        });
    }
});
