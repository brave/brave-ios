# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Entry point for interacting with depot_tools from recipes."""

from recipe_engine import recipe_api

class DepotToolsApi(recipe_api.RecipeApi):
  @property
  def gclient_py(self):
    return self.package_resource('gclient.py')
