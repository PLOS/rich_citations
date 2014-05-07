/**
  * @jsx React.DOM 
  */

var stopWords = [/\ba\b/g,/\babout\b/g,/\babove\b/g,/\bafter\b/g,/\bagain\b/g,/\bagainst\b/g,/\ball\b/g,/\bam\b/g,/\ban\b/g,/\band\b/g,/\bany\b/g,/\bare\b/g,/\baren't\b/g,/\bas\b/g,/\bat\b/g,/\bbe\b/g,/\bbecause\b/g,/\bbeen\b/g,/\bbefore\b/g,/\bbeing\b/g,/\bbelow\b/g,/\bbetween\b/g,/\bboth\b/g,/\bbut\b/g,/\bby\b/g,/\bcan't\b/g,/\bcannot\b/g,/\bcould\b/g,/\bcouldn't\b/g,/\bdid\b/g,/\bdidn't\b/g,/\bdo\b/g,/\bdoes\b/g,/\bdoesn't\b/g,/\bdoing\b/g,/\bdon't\b/g,/\bdown\b/g,/\bduring\b/g,/\beach\b/g,/\bfew\b/g,/\bfor\b/g,/\bfrom\b/g,/\bfurther\b/g,/\bhad\b/g,/\bhadn't\b/g,/\bhas\b/g,/\bhasn't\b/g,/\bhave\b/g,/\bhaven't\b/g,/\bhaving\b/g,/\bhe\b/g,/\bhe'd\b/g,/\bhe'll\b/g,/\bhe's\b/g,/\bher\b/g,/\bhere\b/g,/\bhere's\b/g,/\bhers\b/g,/\bherself\b/g,/\bhim\b/g,/\bhimself\b/g,/\bhis\b/g,/\bhow\b/g,/\bhow's\b/g,/\bi\b/g,/\bi'd\b/g,/\bi'll\b/g,/\bi'm\b/g,/\bi've\b/g,/\bif\b/g,/\bin\b/g,/\binto\b/g,/\bis\b/g,/\bisn't\b/g,/\bit\b/g,/\bit's\b/g,/\bits\b/g,/\bitself\b/g,/\blet's\b/g,/\bme\b/g,/\bmore\b/g,/\bmost\b/g,/\bmustn't\b/g,/\bmy\b/g,/\bmyself\b/g,/\bno\b/g,/\bnor\b/g,/\bnot\b/g,/\bof\b/g,/\boff\b/g,/\bon\b/g,/\bonce\b/g,/\bonly\b/g,/\bor\b/g,/\bother\b/g,/\bought\b/g,/\bour\b/g,/\bours 	ourselves\b/g,/\bout\b/g,/\bover\b/g,/\bown\b/g,/\bsame\b/g,/\bshan't\b/g,/\bshe\b/g,/\bshe'd\b/g,/\bshe'll\b/g,/\bshe's\b/g,/\bshould\b/g,/\bshouldn't\b/g,/\bso\b/g,/\bsome\b/g,/\bsuch\b/g,/\bthan\b/g,/\bthat\b/g,/\bthat's\b/g,/\bthe\b/g,/\btheir\b/g,/\btheirs\b/g,/\bthem\b/g,/\bthemselves\b/g,/\bthen\b/g,/\bthere\b/g,/\bthere's\b/g,/\bthese\b/g,/\bthey\b/g,/\bthey'd\b/g,/\bthey'll\b/g,/\bthey're\b/g,/\bthey've\b/g,/\bthis\b/g,/\bthose\b/g,/\bthrough\b/g,/\bto\b/g,/\btoo\b/g,/\bunder\b/g,/\buntil\b/g,/\bup\b/g,/\bvery\b/g,/\bwas\b/g,/\bwasn't\b/g,/\bwe\b/g,/\bwe'd\b/g,/\bwe'll\b/g,/\bwe're\b/g,/\bwe've\b/g,/\bwere\b/g,/\bweren't\b/g,/\bwhat\b/g,/\bwhat's\b/g,/\bwhen\b/g,/\bwhen's\b/g,/\bwhere\b/g,/\bwhere's\b/g,/\bwhich\b/g,/\bwhile\b/g,/\bwho\b/g,/\bwho's\b/g,/\bwhom\b/g,/\bwhy\b/g,/\bwhy's\b/g,/\bwith\b/g,/\bwon't\b/g,/\bwould\b/g,/\bwouldn't\b/g,/\byou\b/g,/\byou'd\b/g,/\byou'll\b/g,/\byou're\b/g,/\byou've\b/g,/\byour\b/g,/\byours\b/g,/\byourself\b/g,/\byourselves\b/g];

var doi = $('meta[name=citation_doi]').attr("content");

var idx = lunr(function () {
    this.field('title', { boost: 10 });
    this.field('body');
});

function buildIndex(references, json) {
    var refs = getRefListById(json);
    jQuery.makeArray(references).map(function (el) {
        var id = $("a:first", el).attr('id');
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
 * Returns a string appropriate for sort comparison.
 */
function cleanString(s) {
    var retval = s.toLowerCase();
    stopWords.map(function (word) {
        retval = retval.replace(word, '');
    });
    /* clean whitespace */
    retval = retval.replace(/(^\s+|=s+$)/g, '');
    retval = retval.replace(/\s+/g, ' ');
    return retval;
}

/**
 * Build a function that can be passed to filter to remove items that
 * cannot be sorted.
 */
function mkUnsortableFilter(by, json) {
    var refs = getRefListById(json);
    return function (el) {
        var info = getReferenceInfoById(refs, $("a:first", el).attr('id'));
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
    return function (a, b) {
        var aref = getReferenceInfoById(refs, $("a:first", a).attr('id'));
        var bref = getReferenceInfoById(refs, $("a:first", b).attr('id'));
        var aval = getReferenceInfoField(aref, by);
        var bval = getReferenceInfoField(bref, by);
        // XXX too many calls to cleanString
        return cleanString(aval).localeCompare(cleanString(bval));
    };
}
                            
var Reference = React.createClass({
    render: function () {
        return <li dangerouslySetInnerHTML={{__html:this.props.html}} />;
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
    render: function() {
        var refsArray = jQuery.makeArray(this.props.references);
        var sorted, unsorted;
        /* by default return all results */
        var searchResultsFilter = function (e) { return true; };
        if (this.state.filterText) {
            var resultHash = {};
            idx.search(this.state.filterText).map(function (res) {
                return resultHash[res['ref']] = res['score'];
            });
            searchResultsFilter = function (e) {
                return (resultHash[getReferenceId(e)] != null);
            };
        } 
        /* Index is special, we just use the original sort order. */
        if (this.state.sort.by === 'index') {
            sorted = refsArray.filter(searchResultsFilter);
            unsorted = [];
        } else {
            var unsortableFilter = mkUnsortableFilter(this.state.sort.by, this.props.json);
            var sortableFilter = function (el) { return !unsortableFilter(el); };
            var sortFunc = mkSortRefListFunction(this.state.sort.by, this.props.json);
            unsorted = refsArray.filter(unsortableFilter).
                filter(searchResultsFilter);
            sorted = refsArray.filter(sortableFilter).sort(sortFunc).
                filter(searchResultsFilter);
        }
        
        if (this.state.sort.order == "desc") { sorted = sorted.reverse(); }

        /* Build elements for react */
        var mkElementFunc = function (h) {
            return <Reference html={$(h).html()} key={$(h).children("a").attr("id")} />;
        };
        var sortedElements = sorted.map(mkElementFunc);
        var unsortedElements = unsorted.map(mkElementFunc);

        return <div>
            <SearchBar filterText={this.state.filterText} onSearchUpdate={this.handleSearchUpdate}/>
            <ul>
            <li><Sorter name="Index"  by="index"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Title"  by="title"  current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Author" by="author" current={this.state.sort} onClick={this.handleSorterClick}/></li>
            <li><Sorter name="Year"   by="year"   current={this.state.sort} onClick={this.handleSorterClick}/></li>
            </ul>
            <ol className="references">{ sortedElements }</ol>
            <h5>Unsortable</h5>
            <ol className="references">{ unsortedElements }</ol>
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
