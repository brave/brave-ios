!function(e){var t={};function n(i){if(t[i])return t[i].exports;var a=t[i]={i:i,l:!1,exports:{}};return e[i].call(a.exports,a,a.exports,n),a.l=!0,a.exports}n.m=e,n.c=t,n.d=function(e,t,i){n.o(e,t)||Object.defineProperty(e,t,{configurable:!1,enumerable:!0,get:i})},n.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return n.d(t,"a",t),t},n.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},n.p="",n(n.s=11)}([function(e,t){e.exports=function(e){return e.webpackPolyfill||(e.deprecate=function(){},e.paths=[],e.children||(e.children=[]),Object.defineProperty(e,"loaded",{enumerable:!0,get:function(){return e.l}}),Object.defineProperty(e,"id",{enumerable:!0,get:function(){return e.i}}),e.webpackPolyfill=1),e}},,,,,,,,,,,function(e,t,n){n(12),n(13),n(14),n(15),e.exports=n(17)},function(e,t,n){"use strict";var i=window.history.pushState,a=window.history.replaceState;window.history.pushState=function(e,t,n){i.apply(this,arguments),webkit.messageHandlers.historyStateHelper.postMessage({pushState:!0,state:e,title:t,url:n})},window.history.replaceState=function(e,t,n){a.apply(this,arguments),webkit.messageHandlers.historyStateHelper.postMessage({replaceState:!0,state:e,title:t,url:n})}},function(e,t,n){"use strict";Object.defineProperty(window.__firefox__,"NightMode",{enumerable:!1,configurable:!1,writable:!1,value:{enabled:!1}});var i,a="brightness(80%) invert(100%) hue-rotate(180deg)",r="html {\n  -webkit-filter: hue-rotate(180deg) invert(100%) !important;\n}\nimg,video {\n  -webkit-filter: "+a+" !important;\n}";function o(e){e.querySelectorAll('[style*="background"]').forEach(function(e){var t;(e.style.backgroundImage||"").startsWith("url")&&(t=e,l.push(t),t.__firefox__NightMode_originalFilter=t.style.webkitFilter,t.style.webkitFilter=a)})}function s(e){e.style.webkitFilter=e.__firefox__NightMode_originalFilter,delete e.__firefox__NightMode_originalFilter}var l=null,c=new MutationObserver(function(e){e.forEach(function(e){e.addedNodes.forEach(function(e){e.nodeType===Node.ELEMENT_NODE&&o(e)})})});Object.defineProperty(window.__firefox__.NightMode,"setEnabled",{enumerable:!1,configurable:!1,writable:!1,value:function(e){if(e!==window.__firefox__.NightMode.enabled){window.__firefox__.NightMode.enabled=e;var t=i||((i=document.createElement("style")).type="text/css",i.appendChild(document.createTextNode(r)),i);if(e)return l=[],document.documentElement.appendChild(t),o(document),void c.observe(document.documentElement,{childList:!0,subtree:!0});c.disconnect(),l.forEach(s);var n=t.parentNode;n&&n.removeChild(t),l=null,"rgba(0, 0, 0, 0)"===getComputedStyle(document.documentElement)["background-color"]&&(document.documentElement.style.backgroundColor="#fff")}}})},function(e,t,n){"use strict";Object.defineProperty(window.__firefox__,"NoImageMode",{enumerable:!1,configurable:!1,writable:!1,value:{enabled:!1}});var i="__firefox__NoImageMode";Object.defineProperty(window.__firefox__.NoImageMode,"setEnabled",{enumerable:!1,configurable:!1,writable:!1,value:function(e){if(e!==window.__firefox__.NoImageMode.enabled)if(window.__firefox__.NoImageMode.enabled=e,e)!function(){var e="*{background-image:none !important;}img,iframe{visibility:hidden !important;}",t=document.getElementById(i);if(t)t.innerHTML=e;else{var n=document.createElement("style");n.type="text/css",n.id=i,n.appendChild(document.createTextNode(e)),document.documentElement.appendChild(n)}}();else{var t=document.getElementById(i);t&&t.remove(),[].slice.apply(document.getElementsByTagName("img")).forEach(function(e){var t=e.src;e.src="",e.src=t}),[].slice.apply(document.querySelectorAll('[style*="background"]')).forEach(function(e){var t=e.style.backgroundImage;e.style.backgroundImage="none",e.style.backgroundImage=t}),[].slice.apply(document.styleSheets).forEach(function(e){[].slice.apply(e.rules||[]).forEach(function(e){var t=e.style;if(t){var n=t.backgroundImage;t.backgroundImage="none",t.backgroundImage=n}})})}}}),window.addEventListener("DOMContentLoaded",function(e){window.__firefox__.NoImageMode.setEnabled(window.__firefox__.NoImageMode.enabled)})},function(e,t,n){"use strict";var i=!1,a=null,r=null,o=/^http:\/\/localhost:\d+\/reader-mode\/page/,s=".content p > img:only-child, .content p > a:only-child > img:only-child, .content .wp-caption img, .content figure img";function l(e){i&&console.log(e)}function c(e){r&&r.theme&&document.body.classList.remove(r.theme),e&&e.theme&&document.body.classList.add(e.theme),r&&r.fontSize&&document.body.classList.remove("font-size"+r.fontSize),e&&e.fontSize&&document.body.classList.add("font-size"+e.fontSize),r&&r.fontType&&document.body.classList.remove(r.fontType),e&&e.fontType&&document.body.classList.add(e.fontType),r=e}function d(){c(JSON.parse(document.body.getAttribute("data-readerStyle"))),function(){var e=document.getElementById("reader-message");e&&(e.style.display="none");var t=document.getElementById("reader-header");t&&(t.style.display="block");var n=document.getElementById("reader-content");n&&(n.style.display="block")}(),function(){var e=document.getElementById("reader-content");if(e)for(var t=window.innerWidth,n=e.offsetWidth,i=t+"px !important",a=function(e){e._originalWidth||(e._originalWidth=e.offsetWidth);var a=e._originalWidth;a<n&&a>.55*t&&(a=t);var r=Math.max((n-t)/2,(n-a)/2)+"px !important",o="max-width: "+i+";width: "+a+"px !important;margin-left: "+r+";margin-right: "+r+";";e.style.cssText=o},r=document.querySelectorAll(s),o=r.length;--o>=0;){var l=r[o];l.width>0?a(l):l.onload=function(){a(l)}}}()}Object.defineProperty(window.__firefox__,"reader",{enumerable:!1,configurable:!1,writable:!1,value:Object.freeze({checkReadability:function(){setTimeout(function(){if(document.location.href.match(o))return l({Type:"ReaderModeStateChange",Value:"Active"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Active"});if(("http:"===document.location.protocol||"https:"===document.location.protocol)&&"/"!==document.location.pathname){if(a&&a.content)return l({Type:"ReaderModeStateChange",Value:"Available"}),webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Available"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderContentParsed",Value:a});var e=n(16),t={spec:document.location.href,host:document.location.host,prePath:document.location.protocol+"//"+document.location.host,scheme:document.location.protocol.substr(0,document.location.protocol.indexOf(":")),pathBase:document.location.protocol+"//"+document.location.host+location.pathname.substr(0,location.pathname.lastIndexOf("/")+1)},r=(new XMLSerializer).serializeToString(document),s=new e(t,(new DOMParser).parseFromString(r,"text/html"),{debug:i});return l({Type:"ReaderModeStateChange",Value:null!==(a=s.parse())?"Available":"Unavailable"}),webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:null!==a?"Available":"Unavailable"}),void webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderContentParsed",Value:a})}l({Type:"ReaderModeStateChange",Value:"Unavailable"}),webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderModeStateChange",Value:"Unavailable"})},100)},readerize:function(){return a},setStyle:c})}),window.addEventListener("load",function(e){document.location.href.match(o)&&d()}),window.addEventListener("pageshow",function(e){document.location.href.match(o)&&webkit.messageHandlers.readerModeMessageHandler.postMessage({Type:"ReaderPageEvent",Value:"PageShow"})})},function(e,t,n){"use strict";(function(e){var t="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e};function n(e,t,n){var i;n=n||{},this._uri=e,this._doc=t,this._articleTitle=null,this._articleByline=null,this._articleDir=null,this._attempts=[],this._debug=!!n.debug,this._maxElemsToParse=n.maxElemsToParse||this.DEFAULT_MAX_ELEMS_TO_PARSE,this._nbTopCandidates=n.nbTopCandidates||this.DEFAULT_N_TOP_CANDIDATES,this._charThreshold=n.charThreshold||this.DEFAULT_CHAR_THRESHOLD,this._classesToPreserve=this.CLASSES_TO_PRESERVE.concat(n.classesToPreserve||[]),this._flags=this.FLAG_STRIP_UNLIKELYS|this.FLAG_WEIGHT_CLASSES|this.FLAG_CLEAN_CONDITIONALLY,this._debug?(i=function(e){var t=e.nodeName+" ";if(e.nodeType==e.TEXT_NODE)return t+'("'+e.textContent+'")';var n=e.className&&"."+e.className.replace(/ /g,"."),i="";return e.id?i="(#"+e.id+n+")":n&&(i="("+n+")"),t+i},this.log=function(){if("undefined"!=typeof dump){var e=Array.prototype.map.call(arguments,function(e){return e&&e.nodeName?i(e):e}).join(" ");dump("Reader: (Readability) "+e+"\n")}else if("undefined"!=typeof console){var t=["Reader: (Readability) "].concat(arguments);console.log.apply(console,t)}}):this.log=function(){}}n.prototype={FLAG_STRIP_UNLIKELYS:1,FLAG_WEIGHT_CLASSES:2,FLAG_CLEAN_CONDITIONALLY:4,DEFAULT_MAX_ELEMS_TO_PARSE:0,DEFAULT_N_TOP_CANDIDATES:5,DEFAULT_TAGS_TO_SCORE:"section,h2,h3,h4,h5,h6,p,td,pre".toUpperCase().split(","),DEFAULT_CHAR_THRESHOLD:500,REGEXPS:{unlikelyCandidates:/banner|breadcrumbs|combx|comment|community|cover-wrap|disqus|extra|foot|header|legends|menu|related|remark|replies|rss|shoutbox|sidebar|skyscraper|social|sponsor|supplemental|ad-break|agegate|pagination|pager|popup|yom-remote/i,okMaybeItsACandidate:/and|article|body|column|main|shadow/i,positive:/article|body|content|entry|hentry|h-entry|main|page|pagination|post|text|blog|story/i,negative:/hidden|^hid$| hid$| hid |^hid |banner|combx|comment|com-|contact|foot|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|share|shoutbox|sidebar|skyscraper|sponsor|shopping|tags|tool|widget/i,extraneous:/print|archive|comment|discuss|e[\-]?mail|share|reply|all|login|sign|single|utility/i,byline:/byline|author|dateline|writtenby|p-author/i,replaceFonts:/<(\/?)font[^>]*>/gi,normalize:/\s{2,}/g,videos:/\/\/(www\.)?(dailymotion|youtube|youtube-nocookie|player\.vimeo)\.com/i,nextLink:/(next|weiter|continue|>([^\|]|$)|»([^\|]|$))/i,prevLink:/(prev|earl|old|new|<|«)/i,whitespace:/^\s*$/,hasContent:/\S$/},DIV_TO_P_ELEMS:["A","BLOCKQUOTE","DL","DIV","IMG","OL","P","PRE","TABLE","UL","SELECT"],ALTER_TO_DIV_EXCEPTIONS:["DIV","ARTICLE","SECTION","P"],PRESENTATIONAL_ATTRIBUTES:["align","background","bgcolor","border","cellpadding","cellspacing","frame","hspace","rules","style","valign","vspace"],DEPRECATED_SIZE_ATTRIBUTE_ELEMS:["TABLE","TH","TD","HR","PRE"],CLASSES_TO_PRESERVE:["readability-styled","page"],_postProcessContent:function(e){this._fixRelativeUris(e),this._cleanClasses(e)},_removeNodes:function(e,t){for(var n=e.length-1;n>=0;n--){var i=e[n],a=i.parentNode;a&&(t&&!t.call(this,i,n,e)||a.removeChild(i))}},_replaceNodeTags:function(e,t){for(var n=e.length-1;n>=0;n--){var i=e[n];this._setNodeTag(i,t)}},_forEachNode:function(e,t){Array.prototype.forEach.call(e,t,this)},_someNode:function(e,t){return Array.prototype.some.call(e,t,this)},_concatNodeLists:function(){var e=Array.prototype.slice,t=e.call(arguments).map(function(t){return e.call(t)});return Array.prototype.concat.apply([],t)},_getAllNodesWithTag:function(e,t){return e.querySelectorAll?e.querySelectorAll(t.join(",")):[].concat.apply([],t.map(function(t){var n=e.getElementsByTagName(t);return Array.isArray(n)?n:Array.from(n)}))},_cleanClasses:function(e){var t=this._classesToPreserve,n=(e.getAttribute("class")||"").split(/\s+/).filter(function(e){return-1!=t.indexOf(e)}).join(" ");for(n?e.setAttribute("class",n):e.removeAttribute("class"),e=e.firstElementChild;e;e=e.nextElementSibling)this._cleanClasses(e)},_fixRelativeUris:function(e){var t=this._doc.baseURI,n=this._doc.documentURI;function i(e){if(t==n&&"#"==e.charAt(0))return e;try{return new URL(e,t).href}catch(e){}return e}var a=e.getElementsByTagName("a");this._forEachNode(a,function(e){var t=e.getAttribute("href");if(t)if(0===t.indexOf("javascript:")){var n=this._doc.createTextNode(e.textContent);e.parentNode.replaceChild(n,e)}else e.setAttribute("href",i(t))});var r=e.getElementsByTagName("img");this._forEachNode(r,function(e){var t=e.getAttribute("src");t&&e.setAttribute("src",i(t))})},_getArticleTitle:function(){var e=this._doc,t="",n="";try{"string"!=typeof(t=n=e.title)&&(t=n=this._getInnerText(e.getElementsByTagName("title")[0]))}catch(e){}var i=!1;function a(e){return e.split(/\s+/).length}if(/ [\|\-\\\/>»] /.test(t))i=/ [\\\/>»] /.test(t),a(t=n.replace(/(.*)[\|\-\\\/>»] .*/gi,"$1"))<3&&(t=n.replace(/[^\|\-\\\/>»]*[\|\-\\\/>»](.*)/gi,"$1"));else if(-1!==t.indexOf(": ")){var r=this._concatNodeLists(e.getElementsByTagName("h1"),e.getElementsByTagName("h2"));this._someNode(r,function(e){return e.textContent===t})||(a(t=n.substring(n.lastIndexOf(":")+1))<3?t=n.substring(n.indexOf(":")+1):a(n.substr(0,n.indexOf(":")))>5&&(t=n))}else if(t.length>150||t.length<15){var o=e.getElementsByTagName("h1");1===o.length&&(t=this._getInnerText(o[0]))}var s=a(t=t.trim());return s<=4&&(!i||s!=a(n.replace(/[\|\-\\\/>»]+/g,""))-1)&&(t=n),t},_prepDocument:function(){var e=this._doc;this._removeNodes(e.getElementsByTagName("style")),e.body&&this._replaceBrs(e.body),this._replaceNodeTags(e.getElementsByTagName("font"),"SPAN")},_nextElement:function(e){for(var t=e;t&&t.nodeType!=Node.ELEMENT_NODE&&this.REGEXPS.whitespace.test(t.textContent);)t=t.nextSibling;return t},_replaceBrs:function(e){this._forEachNode(this._getAllNodesWithTag(e,["br"]),function(e){for(var t=e.nextSibling,n=!1;(t=this._nextElement(t))&&"BR"==t.tagName;){n=!0;var i=t.nextSibling;t.parentNode.removeChild(t),t=i}if(n){var a=this._doc.createElement("p");for(e.parentNode.replaceChild(a,e),t=a.nextSibling;t;){if("BR"==t.tagName){var r=this._nextElement(t.nextSibling);if(r&&"BR"==r.tagName)break}var o=t.nextSibling;a.appendChild(t),t=o}}})},_setNodeTag:function(e,t){if(this.log("_setNodeTag",e,t),e.__JSDOMParser__)return e.localName=t.toLowerCase(),e.tagName=t.toUpperCase(),e;for(var n=e.ownerDocument.createElement(t);e.firstChild;)n.appendChild(e.firstChild);e.parentNode.replaceChild(n,e),e.readability&&(n.readability=e.readability);for(var i=0;i<e.attributes.length;i++)n.setAttribute(e.attributes[i].name,e.attributes[i].value);return n},_prepArticle:function(e){this._cleanStyles(e),this._markDataTables(e),this._cleanConditionally(e,"form"),this._cleanConditionally(e,"fieldset"),this._clean(e,"object"),this._clean(e,"embed"),this._clean(e,"h1"),this._clean(e,"footer"),this._clean(e,"link"),this._clean(e,"aside"),this._forEachNode(e.children,function(e){this._cleanMatchedNodes(e,/share/)});var t=e.getElementsByTagName("h2");if(1===t.length){var n=(t[0].textContent.length-this._articleTitle.length)/this._articleTitle.length;if(Math.abs(n)<.5){(n>0?t[0].textContent.includes(this._articleTitle):this._articleTitle.includes(t[0].textContent))&&this._clean(e,"h2")}}this._clean(e,"iframe"),this._clean(e,"input"),this._clean(e,"textarea"),this._clean(e,"select"),this._clean(e,"button"),this._cleanHeaders(e),this._cleanConditionally(e,"table"),this._cleanConditionally(e,"ul"),this._cleanConditionally(e,"div"),this._removeNodes(e.getElementsByTagName("p"),function(e){return 0===e.getElementsByTagName("img").length+e.getElementsByTagName("embed").length+e.getElementsByTagName("object").length+e.getElementsByTagName("iframe").length&&!this._getInnerText(e,!1)}),this._forEachNode(this._getAllNodesWithTag(e,["br"]),function(e){var t=this._nextElement(e.nextSibling);t&&"P"==t.tagName&&e.parentNode.removeChild(e)})},_initializeNode:function(e){switch(e.readability={contentScore:0},e.tagName){case"DIV":e.readability.contentScore+=5;break;case"PRE":case"TD":case"BLOCKQUOTE":e.readability.contentScore+=3;break;case"ADDRESS":case"OL":case"UL":case"DL":case"DD":case"DT":case"LI":case"FORM":e.readability.contentScore-=3;break;case"H1":case"H2":case"H3":case"H4":case"H5":case"H6":case"TH":e.readability.contentScore-=5}e.readability.contentScore+=this._getClassWeight(e)},_removeAndGetNext:function(e){var t=this._getNextNode(e,!0);return e.parentNode.removeChild(e),t},_getNextNode:function(e,t){if(!t&&e.firstElementChild)return e.firstElementChild;if(e.nextElementSibling)return e.nextElementSibling;do{e=e.parentNode}while(e&&!e.nextElementSibling);return e&&e.nextElementSibling},_getNextNodeNoElementProperties:function(e,t){function n(e){do{e=e.nextSibling}while(e&&e.nodeType!==e.ELEMENT_NODE);return e}if(!t&&e.children[0])return e.children[0];var i=n(e);if(i)return i;do{(e=e.parentNode)&&(i=n(e))}while(e&&!i);return e&&i},_checkByline:function(e,t){if(this._articleByline)return!1;if(void 0!==e.getAttribute)var n=e.getAttribute("rel");return!("author"!==n&&!this.REGEXPS.byline.test(t)||!this._isValidByline(e.textContent))&&(this._articleByline=e.textContent.trim(),!0)},_getNodeAncestors:function(e,t){t=t||0;for(var n=0,i=[];e.parentNode&&(i.push(e.parentNode),!t||++n!==t);)e=e.parentNode;return i},_grabArticle:function(e){this.log("**** grabArticle ****");var t=this._doc,n=null!==e;if(!(e=e||this._doc.body))return this.log("No body found in document. Abort."),null;for(var i=e.innerHTML;;){for(var a=this._flagIsActive(this.FLAG_STRIP_UNLIKELYS),r=[],o=this._doc.documentElement;o;){var s=o.className+" "+o.id;if(this._checkByline(o,s))o=this._removeAndGetNext(o);else if(a&&this.REGEXPS.unlikelyCandidates.test(s)&&!this.REGEXPS.okMaybeItsACandidate.test(s)&&"BODY"!==o.tagName&&"A"!==o.tagName)this.log("Removing unlikely candidate - "+s),o=this._removeAndGetNext(o);else if("DIV"!==o.tagName&&"SECTION"!==o.tagName&&"HEADER"!==o.tagName&&"H1"!==o.tagName&&"H2"!==o.tagName&&"H3"!==o.tagName&&"H4"!==o.tagName&&"H5"!==o.tagName&&"H6"!==o.tagName||!this._isElementWithoutContent(o)){if(-1!==this.DEFAULT_TAGS_TO_SCORE.indexOf(o.tagName)&&r.push(o),"DIV"===o.tagName)if(this._hasSinglePInsideElement(o)){var l=o.children[0];o.parentNode.replaceChild(l,o),o=l,r.push(o)}else this._hasChildBlockElement(o)?this._forEachNode(o.childNodes,function(e){if(e.nodeType===Node.TEXT_NODE&&e.textContent.trim().length>0){var n=t.createElement("p");n.textContent=e.textContent,n.style.display="inline",n.className="readability-styled",o.replaceChild(n,e)}}):(o=this._setNodeTag(o,"P"),r.push(o));o=this._getNextNode(o)}else o=this._removeAndGetNext(o)}var c=[];this._forEachNode(r,function(e){if(e.parentNode&&void 0!==e.parentNode.tagName){var t=this._getInnerText(e);if(!(t.length<25)){var n=this._getNodeAncestors(e,3);if(0!==n.length){var i=0;i+=1,i+=t.split(",").length,i+=Math.min(Math.floor(t.length/100),3),this._forEachNode(n,function(e,t){if(e.tagName){if(void 0===e.readability&&(this._initializeNode(e),c.push(e)),0===t)var n=1;else n=1===t?2:3*t;e.readability.contentScore+=i/n}})}}}});for(var d=[],h=0,u=c.length;h<u;h+=1){var g=c[h],f=g.readability.contentScore*(1-this._getLinkDensity(g));g.readability.contentScore=f,this.log("Candidate:",g,"with score "+f);for(var m=0;m<this._nbTopCandidates;m++){var _=d[m];if(!_||f>_.readability.contentScore){d.splice(m,0,g),d.length>this._nbTopCandidates&&d.pop();break}}}var p,b=d[0]||null,y=!1;if(null===b||"BODY"===b.tagName){b=t.createElement("DIV"),y=!0;for(var E=e.childNodes;E.length;)this.log("Moving child out:",E[0]),b.appendChild(E[0]);e.appendChild(b),this._initializeNode(b)}else if(b){for(var N=[],v=1;v<d.length;v++)d[v].readability.contentScore/b.readability.contentScore>=.75&&N.push(this._getNodeAncestors(d[v]));if(N.length>=3)for(p=b.parentNode;"BODY"!==p.tagName;){for(var T=0,S=0;S<N.length&&T<3;S++)T+=Number(N[S].includes(p));if(T>=3){b=p;break}p=p.parentNode}b.readability||this._initializeNode(b),p=b.parentNode;for(var A=b.readability.contentScore,C=A/3;"BODY"!==p.tagName;)if(p.readability){var x=p.readability.contentScore;if(x<C)break;if(x>A){b=p;break}A=p.readability.contentScore,p=p.parentNode}else p=p.parentNode;for(p=b.parentNode;"BODY"!=p.tagName&&1==p.children.length;)p=(b=p).parentNode;b.readability||this._initializeNode(b)}var L=t.createElement("DIV");n&&(L.id="readability-content");for(var w=Math.max(10,.2*b.readability.contentScore),I=(p=b.parentNode).children,M=0,P=I.length;M<P;M++){var O=I[M],R=!1;if(this.log("Looking at sibling node:",O,O.readability?"with score "+O.readability.contentScore:""),this.log("Sibling has score",O.readability?O.readability.contentScore:"Unknown"),O===b)R=!0;else{var D=0;if(O.className===b.className&&""!==b.className&&(D+=.2*b.readability.contentScore),O.readability&&O.readability.contentScore+D>=w)R=!0;else if("P"===O.nodeName){var k=this._getLinkDensity(O),B=this._getInnerText(O),H=B.length;H>80&&k<.25?R=!0:H<80&&H>0&&0===k&&-1!==B.search(/\.( |$)/)&&(R=!0)}}R&&(this.log("Appending node:",O),-1===this.ALTER_TO_DIV_EXCEPTIONS.indexOf(O.nodeName)&&(this.log("Altering sibling:",O,"to div."),O=this._setNodeTag(O,"DIV")),L.appendChild(O),M-=1,P-=1)}if(this._debug&&this.log("Article content pre-prep: "+L.innerHTML),this._prepArticle(L),this._debug&&this.log("Article content post-prep: "+L.innerHTML),y)b.id="readability-page-1",b.className="page";else{var G=t.createElement("DIV");G.id="readability-page-1",G.className="page";for(var F=L.childNodes;F.length;)G.appendChild(F[0]);L.appendChild(G)}this._debug&&this.log("Article content after paging: "+L.innerHTML);var U=!0,V=this._getInnerText(L,!0).length;if(V<this._charThreshold)if(U=!1,e.innerHTML=i,this._flagIsActive(this.FLAG_STRIP_UNLIKELYS))this._removeFlag(this.FLAG_STRIP_UNLIKELYS),this._attempts.push({articleContent:L,textLength:V});else if(this._flagIsActive(this.FLAG_WEIGHT_CLASSES))this._removeFlag(this.FLAG_WEIGHT_CLASSES),this._attempts.push({articleContent:L,textLength:V});else if(this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY))this._removeFlag(this.FLAG_CLEAN_CONDITIONALLY),this._attempts.push({articleContent:L,textLength:V});else{if(this._attempts.push({articleContent:L,textLength:V}),this._attempts.sort(function(e,t){return e.textLength<t.textLength}),!this._attempts[0].textLength)return null;L=this._attempts[0].articleContent,U=!0}if(U){var X=[p,b].concat(this._getNodeAncestors(p));return this._someNode(X,function(e){if(!e.tagName)return!1;var t=e.getAttribute("dir");return!!t&&(this._articleDir=t,!0)}),L}}},_isValidByline:function(e){return("string"==typeof e||e instanceof String)&&((e=e.trim()).length>0&&e.length<100)},_getArticleMetadata:function(){var e={},t={},n=this._doc.getElementsByTagName("meta"),i=/^\s*((twitter)\s*:\s*)?(description|title)\s*$/gi,a=/^\s*og\s*:\s*(description|title)\s*$/gi;return this._forEachNode(n,function(n){var r=n.getAttribute("name"),o=n.getAttribute("property");if(-1===[r,o].indexOf("author")){var s=null;if(i.test(r)?s=r:a.test(o)&&(s=o),s){var l=n.getAttribute("content");l&&(s=s.toLowerCase().replace(/\s/g,""),t[s]=l.trim())}}else e.byline=n.getAttribute("content")}),"description"in t?e.excerpt=t.description:"og:description"in t?e.excerpt=t["og:description"]:"twitter:description"in t&&(e.excerpt=t["twitter:description"]),e.title=this._getArticleTitle(),e.title||("og:title"in t?e.title=t["og:title"]:"twitter:title"in t&&(e.title=t["twitter:title"])),e},_removeScripts:function(e){this._removeNodes(e.getElementsByTagName("script"),function(e){return e.nodeValue="",e.removeAttribute("src"),!0}),this._removeNodes(e.getElementsByTagName("noscript"))},_hasSinglePInsideElement:function(e){return 1==e.children.length&&"P"===e.children[0].tagName&&!this._someNode(e.childNodes,function(e){return e.nodeType===Node.TEXT_NODE&&this.REGEXPS.hasContent.test(e.textContent)})},_isElementWithoutContent:function(e){return e.nodeType===Node.ELEMENT_NODE&&0==e.textContent.trim().length&&(0==e.children.length||e.children.length==e.getElementsByTagName("br").length+e.getElementsByTagName("hr").length)},_hasChildBlockElement:function(e){return this._someNode(e.childNodes,function(e){return-1!==this.DIV_TO_P_ELEMS.indexOf(e.tagName)||this._hasChildBlockElement(e)})},_getInnerText:function(e,t){t=void 0===t||t;var n=e.textContent.trim();return t?n.replace(this.REGEXPS.normalize," "):n},_getCharCount:function(e,t){return t=t||",",this._getInnerText(e).split(t).length-1},_cleanStyles:function(e){if(e&&"svg"!==e.tagName.toLowerCase()){if("readability-styled"!==e.className){for(var t=0;t<this.PRESENTATIONAL_ATTRIBUTES.length;t++)e.removeAttribute(this.PRESENTATIONAL_ATTRIBUTES[t]);-1!==this.DEPRECATED_SIZE_ATTRIBUTE_ELEMS.indexOf(e.tagName)&&(e.removeAttribute("width"),e.removeAttribute("height"))}for(var n=e.firstElementChild;null!==n;)this._cleanStyles(n),n=n.nextElementSibling}},_getLinkDensity:function(e){var t=this._getInnerText(e).length;if(0===t)return 0;var n=0;return this._forEachNode(e.getElementsByTagName("a"),function(e){n+=this._getInnerText(e).length}),n/t},_getClassWeight:function(e){if(!this._flagIsActive(this.FLAG_WEIGHT_CLASSES))return 0;var t=0;return"string"==typeof e.className&&""!==e.className&&(this.REGEXPS.negative.test(e.className)&&(t-=25),this.REGEXPS.positive.test(e.className)&&(t+=25)),"string"==typeof e.id&&""!==e.id&&(this.REGEXPS.negative.test(e.id)&&(t-=25),this.REGEXPS.positive.test(e.id)&&(t+=25)),t},_clean:function(e,t){var n=-1!==["object","embed","iframe"].indexOf(t);this._removeNodes(e.getElementsByTagName(t),function(e){if(n){var t=[].map.call(e.attributes,function(e){return e.value}).join("|");if(this.REGEXPS.videos.test(t))return!1;if(this.REGEXPS.videos.test(e.innerHTML))return!1}return!0})},_hasAncestorTag:function(e,t,n,i){n=n||3,t=t.toUpperCase();for(var a=0;e.parentNode;){if(n>0&&a>n)return!1;if(e.parentNode.tagName===t&&(!i||i(e.parentNode)))return!0;e=e.parentNode,a++}return!1},_getRowAndColumnCount:function(e){for(var t=0,n=0,i=e.getElementsByTagName("tr"),a=0;a<i.length;a++){var r=i[a].getAttribute("rowspan")||0;r&&(r=parseInt(r,10)),t+=r||1;for(var o=0,s=i[a].getElementsByTagName("td"),l=0;l<s.length;l++){var c=s[l].getAttribute("colspan")||0;c&&(c=parseInt(c,10)),o+=c||1}n=Math.max(n,o)}return{rows:t,columns:n}},_markDataTables:function(e){for(var t=e.getElementsByTagName("table"),n=0;n<t.length;n++){var i=t[n];if("presentation"!=i.getAttribute("role"))if("0"!=i.getAttribute("datatable"))if(i.getAttribute("summary"))i._readabilityDataTable=!0;else{var a=i.getElementsByTagName("caption")[0];if(a&&a.childNodes.length>0)i._readabilityDataTable=!0;else{if(["col","colgroup","tfoot","thead","th"].some(function(e){return!!i.getElementsByTagName(e)[0]}))this.log("Data table because found data-y descendant"),i._readabilityDataTable=!0;else if(i.getElementsByTagName("table")[0])i._readabilityDataTable=!1;else{var r=this._getRowAndColumnCount(i);r.rows>=10||r.columns>4?i._readabilityDataTable=!0:i._readabilityDataTable=r.rows*r.columns>10}}}else i._readabilityDataTable=!1;else i._readabilityDataTable=!1}},_cleanConditionally:function(e,t){if(this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY)){var n="ul"===t||"ol"===t;this._removeNodes(e.getElementsByTagName(t),function(e){if(this._hasAncestorTag(e,"table",-1,function(e){return e._readabilityDataTable}))return!1;var t=this._getClassWeight(e);if(this.log("Cleaning Conditionally",e),t+0<0)return!0;if(this._getCharCount(e,",")<10){for(var i=e.getElementsByTagName("p").length,a=e.getElementsByTagName("img").length,r=e.getElementsByTagName("li").length-100,o=e.getElementsByTagName("input").length,s=0,l=e.getElementsByTagName("embed"),c=0,d=l.length;c<d;c+=1)this.REGEXPS.videos.test(l[c].src)||(s+=1);var h=this._getLinkDensity(e),u=this._getInnerText(e).length;return a>1&&i/a<.5&&!this._hasAncestorTag(e,"figure")||!n&&r>i||o>Math.floor(i/3)||!n&&u<25&&(0===a||a>2)&&!this._hasAncestorTag(e,"figure")||!n&&t<25&&h>.2||t>=25&&h>.5||1===s&&u<75||s>1}return!1})}},_cleanMatchedNodes:function(e,t){for(var n=this._getNextNode(e,!0),i=this._getNextNode(e);i&&i!=n;)i=t.test(i.className+" "+i.id)?this._removeAndGetNext(i):this._getNextNode(i)},_cleanHeaders:function(e){for(var t=1;t<3;t+=1)this._removeNodes(e.getElementsByTagName("h"+t),function(e){return this._getClassWeight(e)<0})},_flagIsActive:function(e){return(this._flags&e)>0},_removeFlag:function(e){this._flags=this._flags&~e},isProbablyReaderable:function(e){var t=this._getAllNodesWithTag(this._doc,["p","pre"]),n=this._getAllNodesWithTag(this._doc,["div > br"]);if(n.length){var i=new Set;[].forEach.call(n,function(e){i.add(e.parentNode)}),t=[].concat.apply(Array.from(i),t)}var a=0;return this._someNode(t,function(t){if(e&&!e(t))return!1;var n=t.className+" "+t.id;if(this.REGEXPS.unlikelyCandidates.test(n)&&!this.REGEXPS.okMaybeItsACandidate.test(n))return!1;if(t.matches&&t.matches("li p"))return!1;var i=t.textContent.trim().length;return!(i<140)&&(a+=Math.sqrt(i-140))>20})},parse:function(){if(this._maxElemsToParse>0){var e=this._doc.getElementsByTagName("*").length;if(e>this._maxElemsToParse)throw new Error("Aborting parsing document; "+e+" elements found")}void 0===this._doc.documentElement.firstElementChild&&(this._getNextNode=this._getNextNodeNoElementProperties),this._removeScripts(this._doc),this._prepDocument();var t=this._getArticleMetadata();this._articleTitle=t.title;var n=this._grabArticle();if(!n)return null;if(this.log("Grabbed: "+n.innerHTML),this._postProcessContent(n),!t.excerpt){var i=n.getElementsByTagName("p");i.length>0&&(t.excerpt=i[0].textContent.trim())}var a=n.textContent;return{uri:this._uri,title:this._articleTitle,byline:t.byline||this._articleByline,dir:this._articleDir,content:n.innerHTML,textContent:a,length:a.length,excerpt:t.excerpt}}},"object"===t(e)&&(e.exports=n)}).call(t,n(0)(e))},function(e,t,n){"use strict";webkit.messageHandlers.trackingProtectionStats&&function(){function e(e,t){e&&webkit.messageHandlers.trackingProtectionStats.postMessage({url:e,resourceType:void 0===t?null:t})}function t(){[].slice.apply(document.scripts).forEach(function(t){e(t.src,"script")}),[].slice.apply(document.images).forEach(function(t){0===t.naturalWidth&&e(t.src,"image")})}Object.defineProperty(window.__firefox__,"TrackingProtectionStats",{enumerable:!1,configurable:!1,writable:!1,value:{enabled:!1}}),Object.defineProperty(window.__firefox__.TrackingProtectionStats,"setEnabled",{enumerable:!1,configurable:!1,writable:!1,value:function(e,t){t===SECURITY_TOKEN&&e!==window.__firefox__.TrackingProtectionStats.enabled&&(window.__firefox__.TrackingProtectionStats.enabled=e,o(e))}});var n=null,i=null,a=null,r=null;function o(o){if(!o)return window.removeEventListener("load",t,!1),void(n&&(XMLHttpRequest.prototype.open=n,XMLHttpRequest.prototype.send=i,Image.prototype.src=a,r.disconnect(),n=i=a=r=null));if(!n){window.addEventListener("load",t,!1);var s=XMLHttpRequest.prototype;n||(n=s.open,i=s.send),s.open=function(e,t){return this._url=t,n.apply(this,arguments)},s.send=function(t){return this._tpErrorHandler||(this._tpErrorHandler=function(){e(this._url)},this.addEventListener("error",this._tpErrorHandler)),i.apply(this,arguments)},a||(a=Object.getOwnPropertyDescriptor(Image.prototype,"src")),delete Image.prototype.src,Object.defineProperty(Image.prototype,"src",{get:function(){return a.get.call(this)},set:function(t){this._tpErrorHandler||(this._tpErrorHandler=function(){e(this.src,"image")},this.addEventListener("error",this._tpErrorHandler)),a.set.call(this,t)}}),(r=new MutationObserver(function(t){t.forEach(function(t){t.addedNodes.forEach(function(t){"SCRIPT"===t.tagName&&t.src&&t.addEventListener("error",function(){e(t.src,"script")})})})})).observe(document.documentElement,{childList:!0,subtree:!0})}}window.__firefox__.TrackingProtectionStats.enabled=!0,o(!0)}()}]);