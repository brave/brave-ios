class $<paymentreq> {
  constructor () {
  }

  canMakePayment() {
    return true;
  }
    
    show() {
        webkit.messageHandlers.U2F.postMessage({ name: 'payment-request-show', data: 'data'})
    }
}

Object.defineProperty(window, 'PaymentRequest', {
  value: $<paymentreq>
})
