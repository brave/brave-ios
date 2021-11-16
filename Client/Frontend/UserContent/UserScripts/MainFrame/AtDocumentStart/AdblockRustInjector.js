"use strict";

Object.defineProperty(window.__firefox__, "AdblockRustInjector", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({
    inject: inject
  })
});

function inject(json) {
    const obj = JSON.parse(atob(json));
    const hide_selectors = obj.hide_selectors;
    const style_selectors = obj.style_selectors;
    const injected_script = obj.injected_script;
    
    window.hide_selectors = hide_selectors;
    window.style_selectors = style_selectors;
    
    var rules = "";

    var head = document.head || document.getElementsByTagName('head')[0];
    var style = document.createElement('style');
    
    // array
    for (const selector of hide_selectors) {
        rules += selector + "{display: none !important}"
    }
    
    for (const key of Object.keys(style_selectors)) {
        const value = style_selectors[key];
        
        var subRules = "";
        
        for(const subRule of value) {
            subRules += subRule + ";"
        }
        
        rules += key + "{" + subRules + "}"
    };

    style.type = 'text/css';
    if (style.styleSheet) {
      style.styleSheet.cssText = rules;
    } else {
      style.appendChild(document.createTextNode(rules));
    }

    head.appendChild(style);
    
//
//    //string
//    for (script of injected_script) {
//        var script = document.createElement("script");
//        script.innerHTML = script;
//        document.head.appendChild(script);
//    }
}

