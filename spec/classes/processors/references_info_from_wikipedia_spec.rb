# Copyright (c) 2014 Nathan Day

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'spec_helper'

describe Processors::ReferencesInfoFromWikipedia do
  include Spec::ProcessorHelper

  complete_response = <<'WIKIPEDIA_HTML'
<!DOCTYPE html>
<html lang="en" dir="ltr" class="client-nojs">
<head>
<meta charset="UTF-8" />
<title>Cite This Page - Wikipedia, the free encyclopedia</title>
<meta name="generator" content="MediaWiki 1.25wmf12" />
<meta name="robots" content="noindex,nofollow" />
<link rel="apple-touch-icon" href="//bits.wikimedia.org/apple-touch/wikipedia.png" />
<link rel="shortcut icon" href="//bits.wikimedia.org/favicon/wikipedia.ico" />
<link rel="search" type="application/opensearchdescription+xml" href="/w/opensearch_desc.php" title="Wikipedia (en)" />
<link rel="EditURI" type="application/rsd+xml" href="//en.wikipedia.org/w/api.php?action=rsd" />
<link rel="alternate" hreflang="x-default" href="/wiki/Special:CiteThisPage" />
<link rel="copyright" href="//creativecommons.org/licenses/by-sa/3.0/" />
<link rel="alternate" type="application/atom+xml" title="Wikipedia Atom feed" href="/w/index.php?title=Special:RecentChanges&amp;feed=atom" />
<link rel="canonical" href="http://en.wikipedia.org/w/index.php?title=Special:CiteThisPage&amp;page=Jean_Tirole" />
<link rel="stylesheet" href="//bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=ext.citeThisPage%2Cwikihiero%2CwikimediaBadges%7Cext.gadget.DRN-wizard%2CReferenceTooltips%2Ccharinsert%2Cfeatured-articles-links%2CrefToolbar%2Cswitcher%2Cteahouse%7Cext.uls.nojs%7Cext.visualEditor.viewPageTarget.noscript%7Cmediawiki.legacy.commonPrint%2Cshared%7Cmediawiki.skinning.interface%7Cmediawiki.ui.button%7Cskins.vector.styles%7Cwikibase.client.nolanglinks&amp;only=styles&amp;skin=vector&amp;*" />
<meta name="ResourceLoaderDynamicStyles" content="" />
<link rel="stylesheet" href="//bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=site&amp;only=styles&amp;skin=vector&amp;*" />
<style>a:lang(ar),a:lang(kk-arab),a:lang(mzn),a:lang(ps),a:lang(ur){text-decoration:none}
/* cache key: enwiki:resourceloader:filter:minify-css:7:3904d24a08aa08f6a68dc338f9be277e */</style>
<script src="//bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=startup&amp;only=scripts&amp;skin=vector&amp;*"></script>
<script>if(window.mw){
mw.config.set({"wgCanonicalNamespace":"Special","wgCanonicalSpecialPageName":"CiteThisPage","wgNamespaceNumber":-1,"wgPageName":"Special:CiteThisPage","wgTitle":"CiteThisPage","wgCurRevisionId":0,"wgRevisionId":0,"wgArticleId":0,"wgIsArticle":false,"wgIsRedirect":false,"wgAction":"view","wgUserName":null,"wgUserGroups":["*"],"wgCategories":[],"wgBreakFrames":true,"wgPageContentLanguage":"en","wgPageContentModel":"wikitext","wgSeparatorTransformTable":["",""],"wgDigitTransformTable":["",""],"wgDefaultDateFormat":"dmy","wgMonthNames":["","January","February","March","April","May","June","July","August","September","October","November","December"],"wgMonthNamesShort":["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"wgRelevantPageName":"Special:CiteThisPage","wgRelevantArticleId":0,"wgIsProbablyEditable":false,"wgWikiEditorEnabledModules":{"toolbar":true,"dialogs":true,"hidesig":true,"preview":false,"publish":false},"wgBetaFeaturesFeatures":[],"wgMediaViewerOnClick":true,"wgMediaViewerEnabledByDefault":true,"wgVisualEditor":{"isPageWatched":false,"pageLanguageCode":"en","pageLanguageDir":"ltr","svgMaxSize":4096,"namespacesWithSubpages":{"6":0,"8":0,"1":true,"2":true,"3":true,"4":true,"5":true,"7":true,"9":true,"10":true,"11":true,"12":true,"13":true,"14":true,"15":true,"100":true,"101":true,"102":true,"103":true,"104":true,"105":true,"106":true,"107":true,"108":true,"109":true,"110":true,"111":true,"830":true,"831":true,"447":true,"2600":false,"828":true,"829":true}},"wikilove-recipient":"","wikilove-anon":0,"wgPoweredByHHVM":true,"wgULSAcceptLanguageList":["en-us","en","es"],"wgULSCurrentAutonym":"English","wgFlaggedRevsParams":{"tags":{"status":{"levels":1,"quality":2,"pristine":3}}},"wgStableRevisionId":null,"wgCategoryTreePageCategoryOptions":"{\"mode\":0,\"hideprefix\":20,\"showcount\":true,\"namespaces\":false}","wgNoticeProject":"wikipedia"});
}</script><script>if(window.mw){
mw.loader.implement("user.options",function($,jQuery){mw.user.options.set({"variant":"en"});},{},{},{});mw.loader.implement("user.tokens",function($,jQuery){mw.user.tokens.set({"editToken":"+\\","patrolToken":"+\\","watchToken":"+\\"});},{},{},{});
/* cache key: enwiki:resourceloader:filter:minify-js:7:94007ea073e20ad4a3cdce36b2f2e369 */
}</script>
<script>if(window.mw){
mw.loader.load(["mediawiki.page.startup","mediawiki.legacy.wikibits","mediawiki.legacy.ajax","ext.centralauth.centralautologin","ext.visualEditor.viewPageTarget.init","ext.uls.init","ext.uls.interface","ext.centralNotice.bannerController","skins.vector.js"]);
}</script>
<link rel="dns-prefetch" href="//meta.wikimedia.org" />
<!--[if lt IE 7]><style type="text/css">body{behavior:url("/w/static-1.25wmf12/skins/Vector/csshover.min.htc")}</style><![endif]-->
</head>
<body class="mediawiki ltr sitedir-ltr ns--1 ns-special mw-special-CiteThisPage page-Special_CiteThisPage skin-vector action-view vector-animateLayout">
		<div id="mw-page-base" class="noprint"></div>
		<div id="mw-head-base" class="noprint"></div>
		<div id="content" class="mw-body" role="main">
			<a id="top"></a>

							<div id="siteNotice"><!-- CentralNotice --></div>
						<div class="mw-indicators">
</div>
			<h1 id="firstHeading" class="firstHeading" lang="en"><span dir="auto">Cite This Page</span></h1>
						<div id="bodyContent" class="mw-body-content">
								<div id="contentSub"></div>
												<div id="jump-to-nav" class="mw-jump">
					Jump to:					<a href="#mw-navigation">navigation</a>, 					<a href="#p-search">search</a>
				</div>
				<div id="mw-content-text"><form id="specialCiteThisPage" method="get" action="/w/index.php"><input type="hidden" value="Special:CiteThisPage" name="title" /><label>Page: <input type="text" size="30" name="page" value="Jean Tirole" /> <input type="submit" value="Cite" /></label></form><div style="width: 90%; text-align: center; font-size: 85%; margin: 10px auto;">Contents:  <a href="#APA_style">APA</a> | <a href="#MLA_style">MLA</a> | <a href="#MHRA_style">MHRA</a> | <a href="#Chicago_style">Chicago</a> | <a href="#CBE.2FCSE_style">CSE</a> | <a href="#Bluebook_style">Bluebook</a> | <a href="#AMA_style">AMA</a> | <a href="#BibTeX_entry">BibTeX</a> | <a href="#Wikipedia_talk_pages">wiki</a> </div>
<p><b>IMPORTANT NOTE:</b> Most educators and professionals do not consider it appropriate to use <a href="/wiki/Tertiary_source" title="Tertiary source">tertiary sources</a> such as encyclopedias as a sole source for any information—citing an encyclopedia as an important reference in footnotes or bibliographies may result in censure or a failing grade.   Wikipedia articles should be used for background information, as a reference for correct terminology and search terms, and as a starting point for further research.
</p><p>As with any <a href="/wiki/Wikipedia:Who_writes_Wikipedia" title="Wikipedia:Who writes Wikipedia">community-built</a> reference, there is a possibility for error in Wikipedia's content—please check your facts against multiple sources and read our <a href="/wiki/Wikipedia:General_disclaimer" title="Wikipedia:General disclaimer">disclaimers</a> for more information.
</p>
<div class="plainlinks" style="border: 1px solid grey; background: #E6E8FA; width: 90%; padding: 15px 30px; margin: 10px auto;">
<h2><span class="mw-headline" id="Bibliographic_details_for_.22Jean_Tirole.22">Bibliographic details for "Jean Tirole"</span></h2>
<ul><li> Page name: Jean Tirole </li>
<li> Author: Wikipedia contributors</li>
<li> Publisher: <i>Wikipedia, The Free Encyclopedia</i>. </li>
<li> Date of last revision: 22 December 2014 22:55 UTC</li>
<li> Date retrieved: 2 January 2015 18:52 UTC</li>
<li> Permanent link: <a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a></li>
<li> Primary contributors:  <a rel="nofollow" class="external text" href="http://vs.aka-online.de/cgi-bin/wppagehiststat.pl?lang=en.wikipedia&amp;page=Jean+Tirole">Revision history statistics</a></li>
<li> Page Version ID: 639251292</li></ul>
<p>Please remember to check your manual of style, standards guide or instructor's guidelines for the exact syntax to suit your needs.  For more detailed advice, see <b><a href="/wiki/Wikipedia:Citing_Wikipedia" title="Wikipedia:Citing Wikipedia">Citing Wikipedia</a></b>.
</p>
</div>
<div class="plainlinks" style="border: 1px solid grey; width: 90%; padding: 15px 30px; margin: 10px auto;">
<h2><span class="mw-headline" id="Citation_styles_for_.22Jean_Tirole.22">Citation styles  for "Jean Tirole"</span></h2>
<h3><span class="mw-headline" id="APA_style"><a href="/wiki/APA_style" title="APA style">APA style</a></span></h3>
<p>Jean Tirole. (2014, December 22).  In <i>Wikipedia, The Free Encyclopedia</i>. Retrieved 18:52, January 2, 2015, from <a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a>
</p>
<h3><span class="mw-headline" id="MLA_style"><a href="/wiki/The_MLA_Style_Manual" title="The MLA Style Manual">MLA style</a></span></h3>
<p>Wikipedia contributors. "Jean Tirole." <i>Wikipedia, The Free Encyclopedia</i>. Wikipedia, The Free Encyclopedia, 22 Dec. 2014. Web. 2 Jan. 2015.
</p>
<h3><span class="mw-headline" id="MHRA_style"><a href="/wiki/MHRA_Style_Guide" title="MHRA Style Guide">MHRA style</a></span></h3>
<p>Wikipedia contributors, 'Jean Tirole',  <i>Wikipedia, The Free Encyclopedia,</i> 22 December 2014, 22:55 UTC, &lt;<a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a>&gt; [accessed 2 January 2015]
</p>
<h3><span class="mw-headline" id="Chicago_style"><a href="/wiki/The_Chicago_Manual_of_Style" title="The Chicago Manual of Style">Chicago style</a></span></h3>
<p>Wikipedia contributors, "Jean Tirole,"  <i>Wikipedia, The Free Encyclopedia,</i> <a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a> (accessed January 2, 2015).
</p>
<h3><span class="mw-headline" id="CBE.2FCSE_style"><a href="/wiki/Council_of_Science_Editors" title="Council of Science Editors">CBE/CSE style</a></span></h3>
<p>Wikipedia contributors. Jean Tirole [Internet].  Wikipedia, The Free Encyclopedia;  2014 Dec 22, 22:55 UTC [cited 2015 Jan 2].  Available from:
<a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a>.
</p>
<h3><span class="mw-headline" id="Bluebook_style"><a href="/wiki/Bluebook" title="Bluebook">Bluebook style</a></span></h3>
<p>Jean Tirole, <a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a> (last visited Jan. 2, 2015).
</p>
<h3><span class="mw-headline" id="AMA_style"><a href="/wiki/American_Medical_Association" title="American Medical Association">AMA</a> style</span></h3>
<p>Wikipedia contributors. Jean Tirole. Wikipedia, The Free Encyclopedia. December 22, 2014, 22:55 UTC. Available at: <a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a>. Accessed January 2, 2015.
</p>
<h3><span class="mw-headline" id="BibTeX_entry"><a href="/wiki/BibTeX" title="BibTeX">BibTeX</a> entry</span></h3>
<pre> @misc{ wiki:xxx,
   author = "Wikipedia",
   title = "Jean Tirole --- Wikipedia{,} The Free Encyclopedia",
   year = "2014",
   url = "<a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a>",
   note = "[Online; accessed 2-January-2015]"
 }
</pre>
<p>When using the <a href="/wiki/LaTeX" title="LaTeX">LaTeX</a> package url (<code>\usepackage{url}</code> somewhere in the preamble), which tends to give much more nicely formatted web addresses, the following may be preferred:
</p>
<pre> @misc{ wiki:xxx,
   author = "Wikipedia",
   title = "Jean Tirole --- Wikipedia{,} The Free Encyclopedia",
   year = "2014",
   url = "<b>\url{</b><a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a><b>}</b>",
   note = "[Online; accessed 2-January-2015]"
 }
</pre>
<h3><span class="mw-headline" id="Wikipedia_talk_pages">Wikipedia talk pages</span></h3>
<dl><dt>Markup</dt>
<dd> [[Jean Tirole]] ([<a class="external free" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292</a> this version])</dd></dl>
<dl><dt>Result</dt>
<dd> <a class="external text" href="http://en.wikipedia.org/wiki/Jean_Tirole">Jean Tirole</a> (<a class="external text" href="http://en.wikipedia.org/w/index.php?title=Jean_Tirole&amp;oldid=639251292">this version</a>)</dd></dl>
</div> <span class="Z3988" title="ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&amp;rfr_id=info%3Asid%2Fen.wikipedia.org%3Aarticle&amp;rft.type=encyclopediaArticle&amp;rft.title=Jean_Tirole&amp;rft.date=2014-12-22&amp;rft.source=Wikipedia%2C+The+Free+Encyclopedia&amp;rft.aucorp=Wikipedia+contributors&amp;rft.publisher=Wikimedia+Foundation&amp;rft.artnum=639251292&amp;rft.identifier=http%3A%2F%2Fen.wikipedia.org%2Fw%2Findex.php%3Ftitle%3DJean_Tirole%26oldid%3D639251292&amp;rft.language=en&amp;rft.format=text&amp;rft.rights=CC-BY-SA+3.0"><span style="display: none;"> </span></span>
<noscript><img src="//en.wikipedia.org/wiki/Special:CentralAutoLogin/start?type=1x1" alt="" title="" width="1" height="1" style="border: none; position: absolute;" /></noscript></div>									<div class="printfooter">
						Retrieved from "<a dir="ltr" href="http://en.wikipedia.org/wiki/Special:CiteThisPage">http://en.wikipedia.org/wiki/Special:CiteThisPage</a>"					</div>
													<div id='catlinks' class='catlinks catlinks-allhidden'></div>												<div class="visualClear"></div>
							</div>
		</div>
		<div id="mw-navigation">
			<h2>Navigation menu</h2>

			<div id="mw-head">
									<div id="p-personal" role="navigation" class="" aria-labelledby="p-personal-label">
						<h3 id="p-personal-label">Personal tools</h3>
						<ul>
							<li id="pt-createaccount"><a href="/w/index.php?title=Special:UserLogin&amp;returnto=Special%3ACiteThisPage&amp;returntoquery=page%3DJean_Tirole&amp;type=signup" title="You are encouraged to create an account and log in; however, it is not mandatory">Create account</a></li><li id="pt-login"><a href="/w/index.php?title=Special:UserLogin&amp;returnto=Special%3ACiteThisPage&amp;returntoquery=page%3DJean_Tirole" title="You&#039;re encouraged to log in; however, it&#039;s not mandatory. [o]" accesskey="o">Log in</a></li>						</ul>
					</div>
									<div id="left-navigation">
										<div id="p-namespaces" role="navigation" class="vectorTabs" aria-labelledby="p-namespaces-label">
						<h3 id="p-namespaces-label">Namespaces</h3>
						<ul>
															<li  id="ca-nstab-special" class="selected"><span><a href="/w/index.php?title=Special:CiteThisPage&amp;page=Jean_Tirole"  title="This is a special page which you cannot edit">Special page</a></span></li>
													</ul>
					</div>
										<div id="p-variants" role="navigation" class="vectorMenu emptyPortlet" aria-labelledby="p-variants-label">
												<h3 id="p-variants-label"><span>Variants</span><a href="#"></a></h3>

						<div class="menu">
							<ul>
															</ul>
						</div>
					</div>
									</div>
				<div id="right-navigation">
										<div id="p-views" role="navigation" class="vectorTabs emptyPortlet" aria-labelledby="p-views-label">
						<h3 id="p-views-label">Views</h3>
						<ul>
													</ul>
					</div>
										<div id="p-cactions" role="navigation" class="vectorMenu emptyPortlet" aria-labelledby="p-cactions-label">
						<h3 id="p-cactions-label"><span>More</span><a href="#"></a></h3>

						<div class="menu">
							<ul>
															</ul>
						</div>
					</div>
										<div id="p-search" role="search">
						<h3>
							<label for="searchInput">Search</label>
						</h3>

						<form action="/w/index.php" id="searchform">
														<div id="simpleSearch">
															<input type="search" name="search" placeholder="Search" title="Search Wikipedia [f]" accesskey="f" id="searchInput" /><input type="hidden" value="Special:Search" name="title" /><input type="submit" name="fulltext" value="Search" title="Search Wikipedia for this text" id="mw-searchButton" class="searchButton mw-fallbackSearchButton" /><input type="submit" name="go" value="Go" title="Go to a page with this exact name if one exists" id="searchButton" class="searchButton" />								</div>
						</form>
					</div>
									</div>
			</div>
			<div id="mw-panel">
				<div id="p-logo" role="banner"><a class="mw-wiki-logo" href="/wiki/Main_Page"  title="Visit the main page"></a></div>
						<div class="portal" role="navigation" id='p-navigation' aria-labelledby='p-navigation-label'>
			<h3 id='p-navigation-label'>Navigation</h3>

			<div class="body">
									<ul>
													<li id="n-mainpage-description"><a href="/wiki/Main_Page" title="Visit the main page [z]" accesskey="z">Main page</a></li>
													<li id="n-contents"><a href="/wiki/Portal:Contents" title="Guides to browsing Wikipedia">Contents</a></li>
													<li id="n-featuredcontent"><a href="/wiki/Portal:Featured_content" title="Featured content – the best of Wikipedia">Featured content</a></li>
													<li id="n-currentevents"><a href="/wiki/Portal:Current_events" title="Find background information on current events">Current events</a></li>
													<li id="n-randompage"><a href="/wiki/Special:Random" title="Load a random article [x]" accesskey="x">Random article</a></li>
													<li id="n-sitesupport"><a href="https://donate.wikimedia.org/wiki/Special:FundraiserRedirector?utm_source=donate&amp;utm_medium=sidebar&amp;utm_campaign=C13_en.wikipedia.org&amp;uselang=en" title="Support us">Donate to Wikipedia</a></li>
													<li id="n-shoplink"><a href="//shop.wikimedia.org" title="Visit the Wikimedia Shop">Wikimedia Shop</a></li>
											</ul>
							</div>
		</div>
			<div class="portal" role="navigation" id='p-interaction' aria-labelledby='p-interaction-label'>
			<h3 id='p-interaction-label'>Interaction</h3>

			<div class="body">
									<ul>
													<li id="n-help"><a href="/wiki/Help:Contents" title="Guidance on how to use and edit Wikipedia">Help</a></li>
													<li id="n-aboutsite"><a href="/wiki/Wikipedia:About" title="Find out about Wikipedia">About Wikipedia</a></li>
													<li id="n-portal"><a href="/wiki/Wikipedia:Community_portal" title="About the project, what you can do, where to find things">Community portal</a></li>
													<li id="n-recentchanges"><a href="/wiki/Special:RecentChanges" title="A list of recent changes in the wiki [r]" accesskey="r">Recent changes</a></li>
													<li id="n-contactpage"><a href="//en.wikipedia.org/wiki/Wikipedia:Contact_us">Contact page</a></li>
											</ul>
							</div>
		</div>
			<div class="portal" role="navigation" id='p-tb' aria-labelledby='p-tb-label'>
			<h3 id='p-tb-label'>Tools</h3>

			<div class="body">
									<ul>
													<li id="t-upload"><a href="/wiki/Wikipedia:File_Upload_Wizard" title="Upload files [u]" accesskey="u">Upload file</a></li>
													<li id="t-specialpages"><a href="/wiki/Special:SpecialPages" title="A list of all special pages [q]" accesskey="q">Special pages</a></li>
													<li id="t-print"><a href="/w/index.php?title=Special:CiteThisPage&amp;page=Jean_Tirole&amp;printable=yes" rel="alternate" title="Printable version of this page [p]" accesskey="p">Printable version</a></li>
											</ul>
							</div>
		</div>
			<div class="portal" role="navigation" id='p-lang' aria-labelledby='p-lang-label'>
			<h3 id='p-lang-label'>Languages</h3>

			<div class="body">
									<ul>
													<li class="uls-p-lang-dummy"><a href="#"></a></li>
											</ul>
							</div>
		</div>
				</div>
		</div>
		<div id="footer" role="contentinfo">
							<ul id="footer-places">
											<li id="footer-places-privacy"><a href="//wikimediafoundation.org/wiki/Privacy_policy" title="wikimedia:Privacy policy">Privacy policy</a></li>
											<li id="footer-places-about"><a href="/wiki/Wikipedia:About" title="Wikipedia:About">About Wikipedia</a></li>
											<li id="footer-places-disclaimer"><a href="/wiki/Wikipedia:General_disclaimer" title="Wikipedia:General disclaimer">Disclaimers</a></li>
											<li id="footer-places-contact"><a href="//en.wikipedia.org/wiki/Wikipedia:Contact_us">Contact Wikipedia</a></li>
											<li id="footer-places-developers"><a href="https://www.mediawiki.org/wiki/Special:MyLanguage/How_to_contribute">Developers</a></li>
											<li id="footer-places-mobileview"><a href="//en.m.wikipedia.org/w/index.php?title=Special:CiteThisPage&amp;page=Jean_Tirole&amp;mobileaction=toggle_view_mobile" class="noprint stopMobileRedirectToggle">Mobile view</a></li>
									</ul>
										<ul id="footer-icons" class="noprint">
											<li id="footer-copyrightico">
															<a href="//wikimediafoundation.org/"><img src="//bits.wikimedia.org/images/wikimedia-button.png" srcset="//bits.wikimedia.org/images/wikimedia-button-1.5x.png 1.5x, //bits.wikimedia.org/images/wikimedia-button-2x.png 2x" width="88" height="31" alt="Wikimedia Foundation"/></a>
													</li>
											<li id="footer-poweredbyico">
															<a href="//www.mediawiki.org/"><img src="//bits.wikimedia.org/static-1.25wmf12/resources/assets/poweredby_mediawiki_88x31.png" alt="Powered by MediaWiki" width="88" height="31" /></a>
													</li>
									</ul>
						<div style="clear:both"></div>
		</div>
		<script>/*<![CDATA[*/window.jQuery && jQuery.ready();/*]]>*/</script><script>if(window.mw){
mw.loader.state({"ext.globalCssJs.site":"ready","ext.globalCssJs.user":"ready","site":"loading","user":"ready","user.groups":"ready"});
}</script>
<script>if(window.mw){
mw.loader.load(["mediawiki.user","mediawiki.hidpi","mediawiki.page.ready","mediawiki.searchSuggest","ext.gadget.teahouse","ext.gadget.ReferenceTooltips","ext.gadget.DRN-wizard","ext.gadget.charinsert","ext.gadget.refToolbar","ext.gadget.switcher","ext.gadget.featured-articles-links","ext.eventLogging.subscriber","ext.wikimediaEvents","ext.wikimediaEvents.statsd","ext.navigationTiming","schema.UniversalLanguageSelector","ext.uls.eventlogger","ext.uls.interlanguage"],null,true);
}</script>
<script>if(window.mw){
document.write("\u003Cscript src=\"//bits.wikimedia.org/en.wikipedia.org/load.php?debug=false\u0026amp;lang=en\u0026amp;modules=site\u0026amp;only=scripts\u0026amp;skin=vector\u0026amp;*\"\u003E\u003C/script\u003E");
}</script>
<script>if(window.mw){
mw.config.set({"wgBackendResponseTime":124,"wgHostname":"mw1243"});
}</script>
	</body>
</html>
WIKIPEDIA_HTML

  it "should call the API" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return(
      'ref-1' => { uri_type: :wikipedia, uri: 'http://en.wikipedia.org/wiki/Jean_Tirole'}
    )
    expect(HttpUtilities).to receive(:get).with('http://en.wikipedia.org/w/index.php?title=Special:CiteThisPage&page=Jean_Tirole').and_return('{}')
    process
  end

  it "should not call the API if there are cached results" do
    expect(HttpUtilities).to_not receive(:get)
    cached = { references: [
        { id:       'ref-1',
          uri_type: :wikipedia,
          uri:      '11112222',
          bibliographic: {
              bib_source: 'cached',
              title:      'cached title'
          }
        }
    ]}
    process(cached)
    ref_info = result[:references].first[:bibliographic]
    expect(ref_info[:bib_source]).to eq('cached')
    expect(ref_info[:title]).to eq('cached title')
  end

  it "should merge in the API results" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return(
      'ref-1' => { uri_type: :wikipedia, uri: 'http://en.wikipedia.org/wiki/Jean_Tirole'}
    )
    expect(HttpUtilities).to receive(:get).and_return(complete_response)
    ref_info = result[:references].first[:bibliographic]
    expect(ref_info).to eq({
      "type"        =>  "encyclopediaArticle",
      "title"       =>  "Jean_Tirole",
      "issued"      =>  "2014-12-22",
      "bib_source"  =>  "Wikipedia, The Free Encyclopedia",
      "author"      =>  "Wikipedia contributors",
      "publisher"   =>  "Wikimedia Foundation",
      "URL"         =>  "http://en.wikipedia.org/w/index.php?title=Jean_Tirole&oldid=639251292",
      "language"    =>  "en",
      "license"     =>  "CC-BY-SA 3.0"
    })
  end

  it "should handle URI encoded page names" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return(
      'ref-1' => { uri_type: :wikipedia, uri: 'http://en.wikipedia.org/wiki/Metcalfe%27s_law'}
    )
    response_html = <<'RESPONSE_HTML'
      <!DOCTYPE html>
      <html lang="en" dir="ltr" class="client-nojs">
          <head>
          </head>
          <body class="mediawiki ltr sitedir-ltr ns--1 ns-special mw-special-CiteThisPage page-Special_CiteThisPage skin-vector action-view vector-animateLayout">
              <span class="Z3988" title="ctx_ver=Z39.88-2004&amp;rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Adc&amp;rfr_id=info%3Asid%2Fen.wikipedia.org%3Aarticle&amp;rft.type=encyclopediaArticle&amp;rft.title=Metcalfe%27s_law&amp;rft.date=2014-12-09&amp;rft.source=Wikipedia%2C+The+Free+Encyclopedia&amp;rft.aucorp=Wikipedia+contributors&amp;rft.publisher=Wikimedia+Foundation&amp;rft.artnum=637300347&amp;rft.identifier=http%3A%2F%2Fen.wikipedia.org%2Fw%2Findex.php%3Ftitle%3DMetcalfe%2527s_law%26oldid%3D637300347&amp;rft.language=en&amp;rft.format=text&amp;rft.rights=CC-BY-SA+3.0"><span style="display: none;"> </span></span>
          </body>
      </html>
RESPONSE_HTML
    expect(HttpUtilities).to receive(:get).and_return(response_html)
    ref_info = result[:references].first[:bibliographic]
    expect(ref_info).to eq({
      "type"        =>  "encyclopediaArticle",
      "title"       =>  "Metcalfe's_law",
      "issued"      =>  "2014-12-09",
      "bib_source"  =>  "Wikipedia, The Free Encyclopedia",
      "author"      =>  "Wikipedia contributors",
      "publisher"   =>  "Wikimedia Foundation",
      "URL"         =>  "http://en.wikipedia.org/w/index.php?title=Metcalfe%27s_law&oldid=637300347",
      "language"    =>  "en",
      "license"     =>  "CC-BY-SA 3.0"
    })
  end


end
