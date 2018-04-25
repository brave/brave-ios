LUCI Hacks - A set of shims used to provide an iterable end-to-end demo.

The main goal of Luci Hakcs is to be able to use iterate on Milo as if it was
displaying real data.  These are a couple of hacks used to get LUCI running from
"git cl try --luci" to displaying a page on Milo.  These include:

luci_recipe_run.py:
* Downloading a depot_tools tarball onto swarming from Google Storage to bootstrap gclient.
** LUCI shouldn't require depot_tools or gclient.
* Running gclient on a swarming slave to bootstrap a full build+infra checkout.
** M1: This should check out the recipes repo instead.
** M2: The recipes repo should have been already isolated.
* Seeding properties by emitting annotation in stdout so that Milo can pick it
  up
* Running annotated_run.py from a fake build directory "build/slave/bot/build"

trigger_luci_job.py:
* Master/Builder -> Recipe + Platform mapping is hardcoded into this file.  This
  is information that is otherwise encoded into master.cfg/slaves.cfg.
** Actually I lied, we just assume linux right now.
** M1: This information should be encoded into the recipe via luci.cfg
* Swarming client is checked out via "git clone <swarming repo>"
* Swarming server is hard coded into the file.  This info should also be pulled
  out from luci.cfg
* Triggering is done directly to swarming.  Once Swarming is able to pull from
  DM we can send jobs to DM instead of swarming.


Misc:
* This just runs the full recipe on the bot.  Yes, including bot_update.
** In the future this would be probably an isolated checkout?
** This also includes having git_cache either set up a local cache, or download
   the bootstrap zip file on every invocation.  In reality there isn't a huge
   time penalty for doing this, but at scale it does incur a non-trival amount of
   unnecessary bandwidth.
