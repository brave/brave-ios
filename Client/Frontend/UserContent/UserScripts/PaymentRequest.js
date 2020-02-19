paymentreq_reject = {}
paymentreq_resolve = {}

Object.defineProperty(window, 'paymentreq_postCreate', {
  value:
    function (response) {
      paymentreq_resolve(response)
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
        paymentreq_resolve = resolve
        paymentreq_reject = reject
        webkit.messageHandlers.PaymentRequest.postMessage({ name: 'payment-request-show', supportedInstruments: supportedInstruments, details: details })
      }
    )
  }
}

Object.defineProperty(window, 'PaymentRequest', {
  value: $<paymentreq>
})
