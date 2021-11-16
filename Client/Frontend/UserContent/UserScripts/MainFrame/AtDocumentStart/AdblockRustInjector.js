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
    
    // array
    for (const selector of hide_selectors) {
        for (const e of document.querySelectorAll(selector)) {
            e.style.display = 'none';
        }
    }
    
    var observer = new MutationObserver(function(mutations) {
        for (const selector of hide_selectors) {
            for (const e of document.querySelectorAll(selector)) {
                e.style.display = 'none';
            }
        }
    });

    observer.observe(document, {
        attributes: true,
        childList: true,
        characterData: true,
        subtree: true
    });
    
//    // dictionary
//    for (selector of style_selectors) {
//        for (e of document.querySelectorAll(selector)) {
//            console.log(e);
//        }
//    }
//
//    //string
//    for (script of injected_script) {
//        var script = document.createElement("script");
//        script.innerHTML = script;
//        document.head.appendChild(script);
//    }
}

