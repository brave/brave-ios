// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const resizePlayer = () => {
  let height = document.documentElement.clientHeight
  let playerElement = document.getElementById('player')
  let playerContainerElement = document.getElementById('player-container')
  let playerHeight = playerElement.clientHeight
  playerContainerElement.style.height = height + 'px'
  playerContainerElement.style.display = 'block'
  console.log(height, playerHeight)

  if (height < playerHeight || height == 0) {
    playerElement.style.marginTop = 'auto'
  } else {
    playerElement.style.marginTop = (height - playerElement.clientHeight) / 2 + 'px'
  }
  
}

window.addEventListener('resize', (event) => {
  resizePlayer()
})

window.addEventListener("load", (event) => {
  resizePlayer()
})

