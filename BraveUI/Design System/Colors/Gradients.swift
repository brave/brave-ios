// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

final public class Gradients {
  public class Light {
    public static var gradient02: CAGradientLayer {
      return CAGradientLayer().then {
        $0.colors = [
            UIColor(red: 0.435, green: 0.298, blue: 0.824, alpha: 1).cgColor,
            UIColor(red: 0.749, green: 0.078, blue: 0.635, alpha: 1).cgColor,
            UIColor(red: 0.969, green: 0.227, blue: 0.11, alpha: 1).cgColor
        ]
        
        $0.locations = [0, 0.56, 1]
        
        $0.calculatePoints(for: 304.74)
      }
    }
  }
}
