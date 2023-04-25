// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

window.__firefox__.execute(function($) {
  const args = $<args>
  const messageHandler = '$<message_handler>';
  const partinessMessageHandler = '$<partiness_message_handler>';
  
  const sendSelectors = $((ids, classes) => {
    return $.postNativeMessage(messageHandler, {
      "securityToken": SECURITY_TOKEN,
      "data": {
        sourceURL: window.location.href,
        ids: ids,
        classes: classes
      }
    })
  })
  
  const getPartiness = $((urls) => {
    return $.postNativeMessage(partinessMessageHandler, {
      "securityToken": SECURITY_TOKEN,
      "data": {
        sourceURL: window.location.href,
        urls: urls,
      }
    })
  })

  /**
   * Provides a new function which can only be scheduled once at a time.
   *
   * @param onIdle function to run when the thread is less busy
   * @param timeout max time to wait. at or after this time the function will be run regardless of thread noise
   */
  const idleize = (onIdle, timeout) => {
    let idleId
    return function willRunOnIdle () {
      if (idleId !== undefined) {
        return
      }
      idleId = window.setTimeout(() => {
        idleId = undefined
        onIdle()
      }, timeout)
    }
  }

  /**
   * Go through each of the 3 queues, only take 50 items from each one
   * 1. Take 50 selectors from the first queue with any items
   * 2. Determine partyness of matched element:
   *   - If any are 3rd party, keep 'hide' rule and check again later in next queue.
   *   - If any are 1st party, remove 'hide' rule and never check selector again.
   * 3. If we're looking at the 3rd queue, don't requeue any selectors.
   */
  let queueIsSleeping = false
  const pumpIntervalMinMs = 40
  const pumpIntervalMaxMs = 1000
  const maxWorkSize = 60
  const alreadyKnownFirstPartySubtrees = new WeakSet()
  const pumpCosmeticFilterQueuesOnIdle = idleize(() => {
    if (queueIsSleeping) { return }
    let didPumpAnything = false
    let newlyUnhiddenSelectors = new Set()
    // For each "pump", walk through each queue until we find selectors
    // to evaluate. This means that nothing in queue N+1 will be evaluated
    // until queue N is completely empty.
    for (let queueIndex = 0; queueIndex < runQueues.length; queueIndex++) {
      const currentQueue = runQueues[queueIndex]
      if (currentQueue.size === 0) {
        continue
      }

      const currentWorkLoad = Array.from(currentQueue.values()).slice(0, maxWorkSize)
      const comboSelector = currentWorkLoad.join(',')
      const matchingElms = document.querySelectorAll(comboSelector)
      console.debug('PUMPING:')
      console.debug(currentWorkLoad)

      // Will hold selectors identified by _this_ queue pumping, that were
      // newly identified to be matching 1p content.
      // Will be sent to the background script to do the un-hiding.
      const awaiting1stPartyChecks = new Set()
      for (let elementIndex = 0; elementIndex < matchingElms.length; elementIndex++) {
        const aMatchingElm = matchingElms[elementIndex]
        let pendingURLChecks = false
        // Don't recheck elements / subtrees we already know are first party.
        // Once we know something is third party, we never need to evaluate it
        // again.
        if (alreadyKnownFirstPartySubtrees.has(aMatchingElm)) {
          continue
        }

        // If the subtree doesn't have a significant amount of text (e.g., it
        // just says "Advertisement"), then no need to change anything; it should
        // stay hidden.
        if (!showsSignificantText(aMatchingElm)) {
          continue
        }

        // If we find that a subtree is third party, then no need to change
        // anything, leave the selector as "hiding" and move on.
        // This element will likely be checked again on the next 'pump'
        // as long as another element from the selector does not match 1st party.
        const elmSubtreeIsFirstParty = isSubTreeFirstParty(aMatchingElm)
        if (elmSubtreeIsFirstParty === undefined) {
          pendingURLChecks = true
        } else if (!elmSubtreeIsFirstParty) {
          continue
        }

        // If we know this is first party, we don't need to check again
        if (!pendingURLChecks) {
          alreadyKnownFirstPartySubtrees.add(aMatchingElm)
        }

        // Otherwise, we know that the given subtree was evaluated to be
        // first party or is still undknown, so we need to figure out which selector from the combo
        // selector did the matching and handle it accordingly.
        for (let workloadIndex = 0; workloadIndex < currentWorkLoad.length; workloadIndex++) {
          const selector = currentWorkLoad[workloadIndex]
          if (!aMatchingElm.matches(selector)) {
            continue
          }

          // Similarly, if we already know a selector matches 1p content,
          // there is no need to notify the background script again, so
          // we don't need to consider further.
          if (unHiddenSelectors.has(selector)) {
            continue
          }

          if (pendingURLChecks) {
            awaiting1stPartyChecks.add(selector)
          } else {
            newlyUnhiddenSelectors.add(selector)
          }
        }
      }

      const nextQueue = runQueues[queueIndex + 1]
      for (let workloadIndex = 0; workloadIndex < currentWorkLoad.length; workloadIndex++) {
        const selector = currentWorkLoad[workloadIndex]

        // Check if we are still looking for partyness of the selector
        if (awaiting1stPartyChecks.has(selector)) {
          // We are still awaiting results for this selector. In which case, we don't do anything.
          continue
        }

        currentQueue.delete(selector)
        if (newlyUnhiddenSelectors.has(selector)) {
          // Don't requeue selectors we know identify first party content.
          unHiddenSelectors.add(selector)
          hiddenSelectors.delete(selector)
        } else {
          if (nextQueue) {
            nextQueue.add(selector)
          }
        }
      }

      didPumpAnything = true
      sendURLsIfNeeded()

      if (currentQueue.size !== awaiting1stPartyChecks.size) {
        // We go to the next queue if the only remaining values in this queue
        // are the ones that need a first party check. We will leave those for later
        // For now let's process what we know we have in the next queue.
        break
      }
    }

    if (didPumpAnything) {
      if (newlyUnhiddenSelectors.size > 0) {
        setRulesOnStylesheet()
      }

      console.debug('SLEEPING QUEUE')
      queueIsSleeping = true
      window.setTimeout(() => {
        // Set this to false now even though there's a gap in time between now and
        // idle since all other calls to `pumpCosmeticFilterQueuesOnIdle` that occur during this time
        // will be ignored (and nothing else should be calling `pumpCosmeticFilterQueues` straight).
        queueIsSleeping = false
        pumpCosmeticFilterQueuesOnIdle()
      }, pumpIntervalMinMs)
    }
  }, pumpIntervalMaxMs)

  const isElement = (node) => {
    return (node.nodeType === 1)
  }

  const isHTMLElement = (node) => {
    return ('innerText' in node)
  }

  const stripChildTagsFromText = (elm, tagName, text) => {
    const childElms = Array.from(elm.getElementsByTagName(tagName))
    let localText = text
    for (let _i = 0, childElms1 = childElms; _i < childElms1.length; _i++) {
      const anElm = childElms1[_i]
      localText = localText.replaceAll(anElm.innerText, '')
    }
    return localText
  }

  // The cutoff for text ads.  If something has only text in it, it needs to have
  // this many, or more, characters.  Similarly, require it to have a non-trivial
  // number of words in it, to look like an actual text ad.
  const minAdTextChars = 30
  const minAdTextWords = 5
  /**
   * Used to just call innerText on the root of the subtree, but in some cases
   * this will surprisingly include the text content of script nodes
   * (possibly of nodes that haven't been executed yet?).
   *
   * So instead  * we call innerText on the root, and remove the contents of any
   * script or style nodes.
   *
   * @see https://github.com/brave/brave-browser/issues/9955
   */
  const showsSignificantText = (elm) => {
    if (!isHTMLElement(elm)) {
      return false
    }
    const htmlElm = elm
    const tagsTextToIgnore = ['script', 'style']
    let currentText = htmlElm.innerText
    for (let _i = 0, tagsTextToIgnore1 = tagsTextToIgnore; _i < tagsTextToIgnore1.length; _i++) {
      const aTagName = tagsTextToIgnore1[_i]
      currentText = stripChildTagsFromText(htmlElm, aTagName, currentText)
    }
    const trimmedText = currentText.trim()
    if (trimmedText.length < minAdTextChars) {
      return false
    }
    let wordCount = 0
    for (let _a = 0, _b = trimmedText.split(' '); _a < _b.length; _a++) {
      const aWord = _b[_a]
      if (aWord.trim().length === 0) {
        continue
      }
      wordCount += 1
    }
    return wordCount >= minAdTextWords
  }

  const isRelativeUrl = (url) => {
    return (!url.startsWith('//') &&
      !url.startsWith('http://') &&
      !url.startsWith('https://'))
  }

  const urlFirstParty = new Map()
  let pendingURLS = new Set()
  const allURLs = new Set()
  const isFirstPartyUrl = (urlString) => {
    if (isRelativeUrl(urlString)) {
      return true
    }

    try {
      const url = new URL(urlString, window.location.url)
      const isFirstParty = urlFirstParty[url.origin]

      if (isFirstParty === undefined && !allURLs.has(url.origin)) {
        pendingURLS.add(url.origin)
        allURLs.add(url.origin)
      }

      return isFirstParty
    } catch (error) {
      console.error(error)
      return true
    }
  }

  /**
   * Determine whether a subtree should be considered as "first party" content.
   *
   * Uses the following process in making this determination.
   *   - If the subtree contains any first party resources, the subtree is 1p.
   *   - If the subtree contains no remote resources, the subtree is first party.
   *   - Otherwise, its 3rd party.
   *
   * Note that any instances of "url(" or escape characters in style attributes
   * are automatically treated as third-party URLs.  These patterns and special
   * cases were generated from looking at patterns in ads with resources in the
   * style attribute.
   *
   * Similarly, an empty srcdoc attribute is also considered 3p, since many
   * third party ads clear this attribute in practice.
   *
   * Finally, special case some ids we know are used only for third party ads.
   */
  const isSubTreeFirstParty = (elm, possibleQueryResult) => {
    let queryResult
    if (possibleQueryResult) {
      queryResult = possibleQueryResult
    } else {
      queryResult = {
        foundFirstPartyResource: false,
        foundThirdPartyResource: false,
        foundKnownThirdPartyAd: false,
        pendingURLChecks: false
      }
    }
    if (elm.getAttribute) {
      if (elm.hasAttribute('id')) {
        const elmId = elm.getAttribute('id')
        if (elmId.startsWith('google_ads_iframe_') ||
          elmId.startsWith('div-gpt-ad') ||
          elmId.startsWith('adfox_')) {
          queryResult.foundKnownThirdPartyAd = true
          return false
        }
      }
      if (elm.hasAttribute('src')) {
        const elmSrc = elm.getAttribute('src')
        const elmSrcIsFirstParty = isFirstPartyUrl(elmSrc)

        if (elmSrcIsFirstParty === undefined) {
          // We don't have enough information yet
          // to know if it is 1st or 3rd party
          queryResult.pendingURLChecks = true
        } else if (elmSrcIsFirstParty) {
          queryResult.foundFirstPartyResource = true
          return true
        } else {
          queryResult.foundThirdPartyResource = true
        }
      }
      if (elm.hasAttribute('style')) {
        const elmStyle = elm.getAttribute('style')
        if (elmStyle.includes('url(') ||
          elmStyle.includes('//')) {
          queryResult.foundThirdPartyResource = true
        }
      }
      if (elm.hasAttribute('srcdoc')) {
        const elmSrcDoc = elm.getAttribute('srcdoc')
        if (elmSrcDoc.trim() === '') {
          queryResult.foundThirdPartyResource = true
        }
      }
    }

    const subElms = []
    if (elm.firstChild) {
      subElms.push(elm.firstChild)
    }
    if (elm.nextSibling) {
      subElms.push(elm.nextSibling)
    }

    for (const subElm of subElms) {
      isSubTreeFirstParty(subElm, queryResult)
      if (queryResult.foundKnownThirdPartyAd) {
        return false
      }
      if (queryResult.foundFirstPartyResource && !queryResult.pendingURLChecks) {
        return true
      }
    }

    if (queryResult.pendingURLChecks) {
      // If we have pending 1st party checks,
      // we will keep it hidden for now
      return false
    } else {
      return !queryResult.foundThirdPartyResource
    }
  }

  /// Takes selectors and adds them to the style sheet
  const hiddenSelectors = new Set()
  const unHiddenSelectors = new Set()
  const runQueues = [new Set(), new Set(), new Set()]
  const processHideSelectors = (selectors) => {
    if (selectors.length === 0) { return }
    console.debug('HIDING:')
    console.debug(selectors)
    selectors.forEach(selector => {
      if ((typeof selector === 'string') && !hiddenSelectors.has(selector) && !unHiddenSelectors.has(selector)) {
        hiddenSelectors.add(selector)

        if (!args.hideFirstPartyContent) {
          runQueues[0].add(selector)
        }
      }
    })
  }

  /// Takes selectors and adds them to the style sheet
  const allStyleRules = []
  const processStyleSelectors = (styleSelectors) => {
    styleSelectors.forEach(entry => {
      const rule = entry.selector + '{' + entry.rules.join(';') + ';}'
      allStyleRules.push(rule)
    })
  }

  /// Moves the stylesheet to the bottom of the page
  const moveStyleIfNeeded = () => {
    const styleElm = cosmeticStyleSheet

    if (styleElm.nextElementSibling === null || styleElm.parentElement === styleElm) {
      return false
    }

    const targetElm = document.body
    styleElm.parentElement.removeChild(styleElm)
    targetElm.appendChild(styleElm)
    return true
  }

  let cosmeticStyleSheet
  const createStylesheet = () => {
    const targetElm = document.body
    const styleElm = document.createElement('style')
    styleElm.setAttribute('type', 'text/css')
    targetElm.appendChild(styleElm)
    cosmeticStyleSheet = styleElm
  }

  const setRulesOnStylesheet = () => {
    const allHideRules = Array.from(hiddenSelectors).map(selector => {
      return selector + '{display:none !important;}'
    })

    const allRules = allHideRules.concat(allStyleRules)
    const ruleText = allRules.filter(rule => {
      return rule !== undefined && !rule.startsWith(':')
    }).join('')

    cosmeticStyleSheet.innerText = ruleText
  }

  const extractURLIfNeeded = (element) => {
    // If we hide first party content we don't care to check urls for partiness.
    // Otherwise we need to have a src attribute.
    if (args.hideFirstPartyContent || element.hasAttribute === undefined || !element.hasAttribute('src')) {
      return false
    }

    const src = element.getAttribute('src')
    // We don't care about this result.
    // We just want to extract the url.
    isFirstPartyUrl(src)
    // Return true that this has a url
    return true
  }

  const extractDataIfNeeded = (element) => {
    extractSelectors(element)
    return extractURLIfNeeded(element)
  }

  const pendingSelectors = { ids: new Set(), classes: new Set() }
  const allSelectors = new Set()
  const extractSelectors = (element) => {
    if (element.hasAttribute === undefined) {
      return false
    }

    let hasNewSelectors = false

    if (element.hasAttribute('id')) {
      const selector = `#${element.id}`
      if (!allSelectors.has(selector)) {
        pendingSelectors.ids.add(element.id)
        allSelectors.add(selector)
        hasNewSelectors = true
      }
    }

    for (const className of element.classList) {
      const selector = `.${className}`
      if (!allSelectors.has(selector)) {
        pendingSelectors.classes.add(className)
        allSelectors.add(selector)
        hasNewSelectors = true
      }
    }

    return hasNewSelectors
  }

  const hiddenSelectorsForElement = (element) => {
    const result = new Set()

    if (element.hasAttribute === undefined) {
      return result
    }

    return Array.from(hiddenSelectors).filter((selector) => {
      return element.matches(selector)
    })
  }

  const sendURLsIfNeeded = () => {
    if (pendingURLS.size === 0) {
      return Promise.resolve(false)
    }

    const urls = Array.from(pendingURLS)
    pendingURLS = new Set()

    return getPartiness(urls).then((results) => {
      console.debug('PARTINESS:')
      console.debug(results)

      for (const url of urls) {
        const result = results[url]

        if (result === undefined) {
          console.error(`Missing result for ${url}`)
          urlFirstParty[url] = false
          continue
        }

        urlFirstParty[url] = result
      }

      return true
    })
  }

  const sendSelectorsIfNeeded = () => {
    if (pendingSelectors.ids.size === 0 && pendingSelectors.classes.size === 0) {
      return Promise.resolve(false)
    }

    const ids = Array.from(pendingSelectors.ids)
    const classes = Array.from(pendingSelectors.classes)
    pendingSelectors.ids = new Set()
    pendingSelectors.classes = new Set()

    return sendSelectors(ids, classes).then((selectors) => {
      if (!selectors || selectors.length === 0) { return false }
      console.debug('BLOCKED:')
      console.debug(selectors)
      processHideSelectors(selectors)
      return true
    })
  }

  const sendDataIfNeeded = () => {
    return Promise.all([sendSelectorsIfNeeded(), sendURLsIfNeeded()]).then((results) => {
      return {
        newSelectors: results[0],
        newFirstPartyInformation: results[1]
      }
    })
  }

  const unhideSelectorIfNeeded = (node, storage) => {
    if (node === undefined) { return }
    const selectors = hiddenSelectorsForElement(node)
    if (selectors.length === 0) { return }

    if (!showsSignificantText(node)) {
      // If the subtree doesn't have a significant amount of text (e.g., it
      // just says "Advertisement"), then no need to change anything; it should
      // stay hidden.
      return
    }

    // If we find that a subtree is third party, then no need to change
    // anything, leave the selector as "hiding" and move on.
    // This element will likely be checked again on the next 'pump'
    // as long as another element from the selector does not match 1st party.
    const elmSubtreeIsFirstParty = isSubTreeFirstParty(node)
    if (elmSubtreeIsFirstParty) {
      // If this is first party, we need to unhide these selectors
      Array.from(selectors).forEach((selector) => {
        hiddenSelectors.delete(selector)
        unHiddenSelectors.add(selector)
        runQueues[0].delete(selector)
        storage.add(selector)
      })
    }
  }

  const unhideSelectorRecursivelyUpwards = (node, storage) => {
    unhideSelectorIfNeeded(node, storage)

    if (node.parentElement !== undefined && node.parentElement !== document.body) {
      unhideSelectorRecursivelyUpwards(node.parentElement, storage)
    }
  }

  const unhideSelectors = (nodes) => {
    const selectorsUnHidden = new Set()

    nodes.forEach((nodeRef) => {
      const node = nodeRef.deref()
      if (node === undefined) { return }
      unhideSelectorRecursivelyUpwards(node, selectorsUnHidden)
    })

    if (selectorsUnHidden.size > 0) {
      console.debug('UNHIDDEN:')
      console.debug(selectorsUnHidden)
    }

    return selectorsUnHidden.size > 0
  }

  const onURLMutations = (mutations, observer) => {
    let addedNodes = false
    let hasChanges = false
    const nodesWithExtractedURLs = []

    mutations.forEach((mutation) => {
      const changedElm = mutation.target
      switch (mutation.type) {
        case 'childList':
          if (mutation.addedNodes.length > 0) {
            for (const node of mutation.addedNodes) {
              if (!isElement(node)) { continue }
              addedNodes = true

              if (extractDataIfNeeded(node)) {
                nodesWithExtractedURLs.push(new WeakRef(node))
                hasChanges = true
              }
            }
          }

          break

        case 'attributes':
          if (extractDataIfNeeded(changedElm)) {
            nodesWithExtractedURLs.push(new WeakRef(changedElm))
            hasChanges = true
          }

          break
      }
    })

    // Check if anything changed
    if (!hasChanges && !addedNodes) { return }

    // If we have data to send we need to send it
    // On the reply we can perform some duties
    sendDataIfNeeded().then((changes) => {
      if (addedNodes) {
        moveStyleIfNeeded()
      }

      // If we have new url party information,
      // we may need to unhide certain selectors
      let unhidSelectors = false
      if (changes.newFirstPartyInformation && unhideSelectors(nodesWithExtractedURLs)) {
        unhidSelectors = true
      }

      if (changes.newSelectors || unhidSelectors) {
        // To be more efficient, only rewrite rules if we need to.
        setRulesOnStylesheet()
      }
    })
  }

  const startURLMutationObserver = () => {
    const observer = new MutationObserver(onURLMutations)

    const observerConfig = {
      subtree: true,
      childList: true,
      attributeFilter: ['src']
    }

    observer.observe(document.documentElement, observerConfig)
  }

  // Load some static hide rules if they are defined
  if (args.hideSelectors) {
    processHideSelectors(args.hideSelectors)
  }

  // Load some static style selectors if they are defined
  if (args.styleSelectors) {
    processStyleSelectors(args.styleSelectors)
  }

  const extractDataRecursively = (element, nodesWithExtractedURLs) => {
    extractSelectors(element)
    if (extractURLIfNeeded(element)) {
      nodesWithExtractedURLs.push(new WeakRef(element))
    }

    if (element.childNodes !== undefined) {
      element.childNodes.forEach((childNode) => {
        extractDataRecursively(childNode, nodesWithExtractedURLs)
      })
    }
  }

  const start = () => {
    createStylesheet()

    const nodesWithExtractedURLs = []
    extractDataRecursively(document.body, nodesWithExtractedURLs)

    nodesWithExtractedURLs.forEach((nodeRef) => {
      const node = nodeRef.deref()
      if (node === undefined) { return }
      console.debug(node)
    })

    sendDataIfNeeded().then((changes) => {
      unhideSelectors(nodesWithExtractedURLs)
      setRulesOnStylesheet()
      startURLMutationObserver()
      pumpCosmeticFilterQueuesOnIdle()
    })
  }

  window.setTimeout(() => {
    if (document.body) {
      start()
      return
    }

    // Wait until document body is ready
    const timerId = window.setInterval(() => {
      if (!document.body) {
        // we need to wait longer.
        return
      }

      // Body is ready, kill this interval and create the stylesheet
      window.clearInterval(timerId)
      start()
    }, 500)
  }, 0)
});
