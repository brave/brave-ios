//<ytd-player id="ytd-player" context="WEB_PLAYER_CONTEXT_CONFIG_ID_KEVLAR_WATCH" class="style-scope ytd-watch-flexy" style="touch-action: pan-down;">
//  <div id="container" class="style-scope ytd-player"></div>
//  <div class="html5-video-player ytp-transparent ytp-fit-cover-video ytp-hide-info-bar" tabindex="-1" id="movie_player" aria-label="YouTube Video Player"></div>
//  <div class="html5-video-container" data-layer="0"></div>
//  <div class="ytp-gradient-top" data-layer="1"></div>
//</ytd-player>

window.__firefox__.includeOnce("YoutubeQuality", function($) {
  function debugPlayer(player) {
    console.log("List of Functions: ");
    for (var fn in player) {
      if (typeof player[fn] == 'function') {
        console.log(fn);
      }
    }
  }
  
  function findPlayer() {
    return document.getElementById('movie_player') || document.querySelector('.html5-video-player');
  }
  
  // Returns -1 if the api does not exist.
  // If it does exist it returns number of available video qualities of the player.
  function hasAPIsAndEnoughVideoQualities(player) {
    if (!player || typeof player.getAvailableQualityLevels === 'undefined') {
      return -1;
    }
    
    return player.getAvailableQualityLevels().length;
  }

  
  function updatePlayerQuality(player, requestedQuality) {
    let qualities = player.getAvailableQualityLevels();
    if (qualities && qualities.length > 0 && requestedQuality.length > 0) {
      let quality = qualities.includes(requestedQuality) ? requestedQuality : qualities[0];
      
      if (player.setPlaybackQuality) {
        player.setPlaybackQuality(quality);
      }
      
      if (player.setPlaybackQualityRange) {
        player.setPlaybackQualityRange(quality);
      }
      
      // console.log(player.getPlaybackQualityLabel());
    }
  }
  
  var timeout = 0;
  var chosenQuality = "";
  // To not break the site completely, if it fails to upgrade few times we proceed with the default option.
  var attemptCount = 0;
  let maxAttempts = 3;
  
  Object.defineProperty(window.__firefox__, '$<set_youtube_quality>', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: $(function(newVideoQuality) {
      chosenQuality = newVideoQuality;
      
      clearInterval(timeout);
      timeout = setInterval($(() => {
        let player = findPlayer();
        // The api must exist and has at least 1 video quality.
        // Sometimes the video count does not load fast enough and a 500ms retry interval is needed.
        if (hasAPIsAndEnoughVideoQualities(player) > 0 || attemptCount++ > maxAttempts) {
          clearInterval(timeout);
          updatePlayerQuality(player, chosenQuality);
        }
      }), 500);
    })
  });
    
  Object.defineProperty(window.__firefox__, '$<refresh_youtube_quality>', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: $(function() {
      if (chosenQuality.length > 0) {
        window.__firefox__.$<set_youtube_quality>(chosenQuality);
      }
    })
  });
  
  $(function() {
    $.postNativeMessage('$<message_handler>', {
      "securityToken": SECURITY_TOKEN,
      "request": "get_default_quality"
    }).then($(function(quality) {
      window.__firefox__.$<set_youtube_quality>(quality);
    }));
  })();
});
