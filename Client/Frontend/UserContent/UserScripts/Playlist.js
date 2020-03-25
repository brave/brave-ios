
function notifyNode(node) {
    window.webkit.messageHandlers.playlistManager.postMessage({
                                                                  "name": node.title,
                                                                  "src": node.src
                                                                  });
}

function observeNode(node) {
    if (node.observer == null || node.observer === undefined) {
        node.observer = new MutationObserver(function (mutations) {
            notifyNode(node);
        });
        node.observer.observe(node, { attributes: true, attributeFilter: ["src"] });
        notifyNode(node);
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
                });
            });
        });
        node.observer.observe(node, { subtree: true, childList: true });
    }
}

function getAllVideoElements() {
    return document.querySelectorAll('video');
}

//TODO: Modify to not use mutation observers
//TODO: Modify to not use intervals
//^ Fix all of the above using a node.add and node.insert hook instead.
function observePage() {
    observeDocument(document);
    
    // Timeinterval is needed for DailyMotion as their DOM is bad
    var interval = setInterval(function(){
        getAllVideoElements().forEach(function(node) {
            observeNode(node);
            notifyNode(node);
        });
    }, 1000);
    
    var timeout = setTimeout(function() {
        clearInterval(interval);
        clearTimeout(timeout);
    }, 5000);
}

observePage();
