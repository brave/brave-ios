//Cookie should neither be saved nor accessed (local or session) when user has blocked all cookies.
var cookieDesc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie') ||
Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'cookie');
if (cookieDesc && cookieDesc.configurable) {
    Object.defineProperty(document, 'cookie', {
                          get: function () {
                          return "";
                          },
                          set: function (val) {
                          return;
                          }
                          });
}


//Access to localStorage should be denied when user has blocked all Cookies.
var localStDesc = Object.getOwnPropertyDescriptor(window, 'localStorage');
if (localStDesc) {
    Object.defineProperty(window, 'localStorage', {
                          get: function () {
                          var err= new Error();
                          err.name = "BraveSecurityError";
                          err.message = "Access denied for 'localStorage'";
                          throw(err);
                          },
                          });
}
