
function notifyNode(node) {
    var name = node.title;
    if (name == null || name === undefined || name == "") {
        name = document.title;
    }
    
    window.webkit.messageHandlers.playlistManager.postMessage({
                                                                  "name": node.title,
                                                                  "src": node.src,
                                                                  "pageSrc": window.location.href,
                                                                  "pageTitle": document.title,
                                                                  "duration": node.duration !== node.duration ? 0.0 : node.duration
                                                                  });
}

function observeNode(node) {
    if (node.observer == null || node.observer === undefined) {
        node.observer = new MutationObserver(function (mutations) {
            notifyNode(node);
        });
        node.observer.observe(node, { attributes: true, attributeFilter: ["src"] });
        notifyNode(node);
        
        node.addEventListener('loadedmetadata', function() {
            notifyNode(node);
        });
    }
}

function observeDocument(node) {
    if (node.observer == null || node.observer === undefined) {
        node.observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                mutation.addedNodes.forEach(function (node) {
                    if (node.constructor.name == "HTMLVideoElement") {
                        observeNode(node);
                    }
                    else if (node.constructor.name == "HTMLAudioElement") {
                        observeNode(node);
                    }
                    else if (node.constructor.name == "HTMLMediaElement") {
                        console.log("DETECTED MEDIA ELEMENT: " + node.constructor.name);
                    }
                });
            });
        });
        node.observer.observe(node, { subtree: true, childList: true });
    }
}

function getAllVideoElements() {
    return document.querySelectorAll('video');
}

function getAllAudioElements() {
    return document.querySelectorAll('audio');
}

function onReady(fn) {
    if (document.readyState === "complete" || document.readyState === "interactive") {
        setTimeout(fn, 1);
    } else {
        document.addEventListener("DOMContentLoaded", fn);
    }
}

//TODO: Modify to not use mutation observers
//TODO: Modify to not use intervals
//^ Fix all of the above using a node.add and node.insert hook instead.
function observePage() {
    observeDocument(document);
    
//    onReady(function() {
//        getAllVideoElements().forEach(function(node) {
//            observeNode(node);
//            notifyNode(node);
//        });
//    });
    
    // Timeinterval is needed for DailyMotion as their DOM is bad
    var interval = setInterval(function(){
        getAllVideoElements().forEach(function(node) {
            observeNode(node);
            notifyNode(node);
        });
        
        getAllAudioElements().forEach(function(node) {
            observeNode(node);
            notifyNode(node);
        });
    }, 1000);
    
    var timeout = setTimeout(function() {
        clearInterval(interval);
        clearTimeout(timeout);
    }, 10000);
}

observePage();
