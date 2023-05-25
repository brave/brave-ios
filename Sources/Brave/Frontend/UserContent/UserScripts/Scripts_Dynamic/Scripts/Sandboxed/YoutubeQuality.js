//<ytd-player id="ytd-player" context="WEB_PLAYER_CONTEXT_CONFIG_ID_KEVLAR_WATCH" class="style-scope ytd-watch-flexy" style="touch-action: pan-down;">
//  <div id="container" class="style-scope ytd-player"></div>
//  <div class="html5-video-player ytp-transparent ytp-fit-cover-video ytp-hide-info-bar" tabindex="-1" id="movie_player" aria-label="YouTube Video Player"></div>
//  <div class="html5-video-container" data-layer="0"></div>
//  <div class="ytp-gradient-top" data-layer="1"></div>
//</ytd-player>

var requestedQuality = "hd720"

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

function updatePlayerQuality(player, requestedQuality) {
  let qualities = player.getAvailableQualityLevels();
  if (qualities && qualities.length > 0) {
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

let timeout = setInterval(() => {
  let player = findPlayer();
  if (player) {
    clearInterval(timeout);
    
    updatePlayerQuality(player);
  }
}, 2000);
