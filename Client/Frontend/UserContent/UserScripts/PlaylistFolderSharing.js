window.__firefox__.includeOnce("PlaylistFolderSharing", function() {
  function sendMessage(playlistId) {
      if (window.webkit.messageHandlers.$<handler>) {
          window.webkit.messageHandlers.$<handler>.postMessage({
            "securitytoken": "$<security_token>",
            "playlistId": playlistId
          });
      }
  }
  
  if (!window.brave) {
    window.brave = {};
  }
  
  if (!window.brave.playlist) {
    window.brave.playlist = {};
    window.brave.playlist.open = function(playlistId) {
      sendMessage(playlistId);
    };
  }
});
