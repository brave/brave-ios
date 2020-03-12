Object.defineProperty(window, '$<paymentreqcallback>', {
  value: {}
});

Object.defineProperty($<paymentreqcallback>, 'paymentreq_postCreate', {
  value:
    function (response, errorName, errorMessage) {
      if (errorName.length == 0) {
        $<paymentreqcallback>.resolve(response);
        return;
      }
      $<paymentreqcallback>.reject(new DOMException(errorMessage, errorName));
    }
})

Object.defineProperty($<paymentreqcallback>, 'paymentreq_log', {
  value:
    function (log) {
      console.log(log)
    }
})

class $<paymentreq> {
  constructor (supportedInstruments, details) {
      this.supportedInstruments = JSON.stringify(supportedInstruments)
      this.details = JSON.stringify(details)
  }

  canMakePayment() {
    return true;
  }

  show() {
    const supportedInstruments = this.supportedInstruments
    const details = this.details
    return new Promise(
      function (resolve, reject) {
        $<paymentreqcallback>.resolve = resolve
        $<paymentreqcallback>.reject = reject
        webkit.messageHandlers.PaymentRequest.postMessage({ name: 'payment-request-show', supportedInstruments: supportedInstruments, details: details })
      }
    )
  }
}

Object.defineProperty(window, 'PaymentRequest', {
  value: $<paymentreq>
})
