window.loadPluginEntry("monitoring-plugin@1.0.0",(()=>{"use strict";var e,r,t,n,o,a,i,u,l,f,d,c,s,p,h,v,g,m,b,y,w={10636:(e,r,t)=>{var n={MonitoringUI:()=>Promise.all([t.e(212),t.e(218)]).then((()=>()=>t(23115)))},o=(e,r)=>(t.R=r,r=t.o(n,e)?n[e]():Promise.resolve().then((()=>{throw new Error('Module "'+e+'" does not exist in container.')})),t.R=void 0,r),a=(e,r)=>{if(t.S){var n="default",o=t.S[n];if(o&&o!==e)throw new Error("Container initialization failed as it has already been initialized with a different share scope");return t.S[n]=e,t.I(n,r)}};t.d(r,{get:()=>o,init:()=>a})}},j={};function O(e){var r=j[e];if(void 0!==r)return r.exports;var t=j[e]={id:e,loaded:!1,exports:{}};return w[e].call(t.exports,t,t.exports,O),t.loaded=!0,t.exports}return O.m=w,O.c=j,O.n=e=>{var r=e&&e.__esModule?()=>e.default:()=>e;return O.d(r,{a:r}),r},r=Object.getPrototypeOf?e=>Object.getPrototypeOf(e):e=>e.__proto__,O.t=function(t,n){if(1&n&&(t=this(t)),8&n)return t;if("object"==typeof t&&t){if(4&n&&t.__esModule)return t;if(16&n&&"function"==typeof t.then)return t}var o=Object.create(null);O.r(o);var a={};e=e||[null,r({}),r([]),r(r)];for(var i=2&n&&t;"object"==typeof i&&!~e.indexOf(i);i=r(i))Object.getOwnPropertyNames(i).forEach((e=>a[e]=()=>t[e]));return a.default=()=>t,O.d(o,a),o},O.d=(e,r)=>{for(var t in r)O.o(r,t)&&!O.o(e,t)&&Object.defineProperty(e,t,{enumerable:!0,get:r[t]})},O.f={},O.e=e=>Promise.all(Object.keys(O.f).reduce(((r,t)=>(O.f[t](e,r),r)),[])),O.u=e=>(218===e?"exposed-MonitoringUI":e)+"-chunk-"+{11:"f4161159fdc6fac80314",15:"88f26ab4cd823a19d9d3",212:"bf4a4d72c3e722d43c10",213:"836ecf9dfc5b194a0ce5",218:"dd0601f0766a2d8b213e",604:"97bb18c4a76e6999e0c5",966:"7f6b9fc2600b5e8b7e0a"}[e]+".min.js",O.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(e){if("object"==typeof window)return window}}(),O.o=(e,r)=>Object.prototype.hasOwnProperty.call(e,r),t={},n="monitoring-plugin:",O.l=(e,r,o,a)=>{if(t[e])t[e].push(r);else{var i,u;if(void 0!==o)for(var l=document.getElementsByTagName("script"),f=0;f<l.length;f++){var d=l[f];if(d.getAttribute("src")==e||d.getAttribute("data-webpack")==n+o){i=d;break}}i||(u=!0,(i=document.createElement("script")).charset="utf-8",i.timeout=120,O.nc&&i.setAttribute("nonce",O.nc),i.setAttribute("data-webpack",n+o),i.src=e),t[e]=[r];var c=(r,n)=>{i.onerror=i.onload=null,clearTimeout(s);var o=t[e];if(delete t[e],i.parentNode&&i.parentNode.removeChild(i),o&&o.forEach((e=>e(n))),r)return r(n)},s=setTimeout(c.bind(null,void 0,{type:"timeout",target:i}),12e4);i.onerror=c.bind(null,i.onerror),i.onload=c.bind(null,i.onload),u&&document.head.appendChild(i)}},O.r=e=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},O.nmd=e=>(e.paths=[],e.children||(e.children=[]),e),(()=>{O.S={};var e={},r={};O.I=(t,n)=>{n||(n=[]);var o=r[t];if(o||(o=r[t]={}),!(n.indexOf(o)>=0)){if(n.push(o),e[t])return e[t];O.o(O.S,t)||(O.S[t]={});var a=O.S[t],i="monitoring-plugin",u=[];return"default"===t&&((e,r,t,n)=>{var o=a[e]=a[e]||{},u=o[r];(!u||!u.loaded&&(1!=!u.eager?n:i>u.from))&&(o[r]={get:()=>Promise.all([O.e(15),O.e(604),O.e(966)]).then((()=>()=>O(97015))),from:i,eager:!1})})("react-helmet","6.1.0"),e[t]=u.length?Promise.all(u).then((()=>e[t]=1)):1}}})(),O.p="/api/plugins/monitoring-plugin/",o=e=>{var r=e=>e.split(".").map((e=>+e==e?+e:e)),t=/^([^-+]+)?(?:-([^+]+))?(?:\+(.+))?$/.exec(e),n=t[1]?r(t[1]):[];return t[2]&&(n.length++,n.push.apply(n,r(t[2]))),t[3]&&(n.push([]),n.push.apply(n,r(t[3]))),n},a=(e,r)=>{e=o(e),r=o(r);for(var t=0;;){if(t>=e.length)return t<r.length&&"u"!=(typeof r[t])[0];var n=e[t],a=(typeof n)[0];if(t>=r.length)return"u"==a;var i=r[t],u=(typeof i)[0];if(a!=u)return"o"==a&&"n"==u||"s"==u||"u"==a;if("o"!=a&&"u"!=a&&n!=i)return n<i;t++}},i=e=>{var r=e[0],t="";if(1===e.length)return"*";if(r+.5){t+=0==r?">=":-1==r?"<":1==r?"^":2==r?"~":r>0?"=":"!=";for(var n=1,o=1;o<e.length;o++)n--,t+="u"==(typeof(u=e[o]))[0]?"-":(n>0?".":"")+(n=2,u);return t}var a=[];for(o=1;o<e.length;o++){var u=e[o];a.push(0===u?"not("+l()+")":1===u?"("+l()+" || "+l()+")":2===u?a.pop()+" "+a.pop():i(u))}return l();function l(){return a.pop().replace(/^\((.+)\)$/,"$1")}},u=(e,r)=>{if(0 in e){r=o(r);var t=e[0],n=t<0;n&&(t=-t-1);for(var a=0,i=1,l=!0;;i++,a++){var f,d,c=i<e.length?(typeof e[i])[0]:"";if(a>=r.length||"o"==(d=(typeof(f=r[a]))[0]))return!l||("u"==c?i>t&&!n:""==c!=n);if("u"==d){if(!l||"u"!=c)return!1}else if(l)if(c==d)if(i<=t){if(f!=e[i])return!1}else{if(n?f>e[i]:f<e[i])return!1;f!=e[i]&&(l=!1)}else if("s"!=c&&"n"!=c){if(n||i<=t)return!1;l=!1,i--}else{if(i<=t||d<c!=n)return!1;l=!1}else"s"!=c&&"n"!=c&&(l=!1,i--)}}var s=[],p=s.pop.bind(s);for(a=1;a<e.length;a++){var h=e[a];s.push(1==h?p()|p():2==h?p()&p():h?u(h,r):!p())}return!!p()},l=(e,r)=>{var t=O.S[e];if(!t||!O.o(t,r))throw new Error("Shared module "+r+" doesn't exist in shared scope "+e);return t},f=(e,r)=>{var t=e[r];return Object.keys(t).reduce(((e,r)=>!e||!t[e].loaded&&a(e,r)?r:e),0)},d=(e,r,t,n)=>"Unsatisfied version "+t+" from "+(t&&e[r][t].from)+" of shared singleton module "+r+" (required "+i(n)+")",c=(e,r,t,n)=>{var o=f(e,t);return u(n,o)||"undefined"!=typeof console&&console.warn&&console.warn(d(e,t,o,n)),p(e[t][o])},s=(e,r,t)=>{var n=e[r];return(r=Object.keys(n).reduce(((e,r)=>!u(t,r)||e&&!a(e,r)?e:r),0))&&n[r]},p=e=>(e.loaded=1,e.get()),v=(h=e=>function(r,t,n,o){var a=O.I(r);return a&&a.then?a.then(e.bind(e,r,O.S[r],t,n,o)):e(r,O.S[r],t,n,o)})(((e,r,t,n)=>(l(e,t),c(r,0,t,n)))),g=h(((e,r,t,n,o)=>{var a=r&&O.o(r,t)&&s(r,t,n);return a?p(a):o()})),m={},b={37901:()=>v("default","@openshift-console/dynamic-plugin-sdk",[3,0,0,20]),37786:()=>v("default","@patternfly/react-core",[4,4,276,8]),70131:()=>v("default","@patternfly/react-table",[4,4,113,0]),56271:()=>v("default","react",[1,17,0,1]),18170:()=>g("default","react-helmet",[1,6,1,0],(()=>Promise.all([O.e(15),O.e(604)]).then((()=>()=>O(97015))))),60733:()=>v("default","react-i18next",[1,11,8,11]),46556:()=>v("default","react-redux",[4,7,2,2]),55630:()=>v("default","react-router-dom",[2,5,3]),19953:()=>v("default","react",[2,0,14,2]),83357:()=>v("default","react",[,[1,18],[1,17],[1,16,8],1,1]),91454:()=>v("default","react",[0,16,6,0]),63062:()=>v("default","react",[,[1,18,0,0],[1,17,0,0],[1,16,3,0],1,1]),64137:()=>v("default","react",[0,16,3,0])},y={218:[37901,37786,70131,56271,18170,60733,46556,55630,19953,83357,91454],604:[63062,64137]},O.f.consumes=(e,r)=>{O.o(y,e)&&y[e].forEach((e=>{if(O.o(m,e))return r.push(m[e]);var t=r=>{m[e]=0,O.m[e]=t=>{delete O.c[e],t.exports=r()}},n=r=>{delete m[e],O.m[e]=t=>{throw delete O.c[e],r}};try{var o=b[e]();o.then?r.push(m[e]=o.then(t).catch(n)):t(o)}catch(e){n(e)}}))},(()=>{O.b=document.baseURI||self.location.href;var e={398:0};O.f.j=(r,t)=>{var n=O.o(e,r)?e[r]:void 0;if(0!==n)if(n)t.push(n[2]);else if(604!=r){var o=new Promise(((t,o)=>n=e[r]=[t,o]));t.push(n[2]=o);var a=O.p+O.u(r),i=new Error;O.l(a,(t=>{if(O.o(e,r)&&(0!==(n=e[r])&&(e[r]=void 0),n)){var o=t&&("load"===t.type?"missing":t.type),a=t&&t.target&&t.target.src;i.message="Loading chunk "+r+" failed.\n("+o+": "+a+")",i.name="ChunkLoadError",i.type=o,i.request=a,n[1](i)}}),"chunk-"+r,r)}else e[r]=0};var r=(r,t)=>{var n,o,[a,i,u]=t,l=0;if(a.some((r=>0!==e[r]))){for(n in i)O.o(i,n)&&(O.m[n]=i[n]);u&&u(O)}for(r&&r(t);l<a.length;l++)o=a[l],O.o(e,o)&&e[o]&&e[o][0](),e[o]=0},t=self.webpackChunkmonitoring_plugin=self.webpackChunkmonitoring_plugin||[];t.forEach(r.bind(null,0)),t.push=r.bind(null,t.push.bind(t))})(),O.nc=void 0,O(10636)})());