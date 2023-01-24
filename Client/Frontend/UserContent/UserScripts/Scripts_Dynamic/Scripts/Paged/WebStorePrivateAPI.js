// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

window.__firefox__.includeOnce("WebStoreAPI", function($, $Object) {
  let postMessage = $(function(name, data) {
    console.log("POST MESSAGE CALLED!\n");
    
    return $.postNativeMessage('$<message_handler>', {
      "securityToken": SECURITY_TOKEN,
      "name": name,
      "data": data
    });
  });

  // MARK: - Event Emitter

  class EventEmitter {
    addListener(callback) {
      console.log('EVENT EMITTER: ', callback);

      var callbacks = this['callbacks'];
      if (!callbacks) {
        this['callbacks'] = new Array();
      }
      this['callbacks'].push(callback);
    }

    removeListener(callback) {
      const index = this['callbacks'].indexOf(callback);
      if (index > -1) {
        array.splice(index, 1);
      }
    }

    hasListener(listener) {
      return this['callbacks'].indexOf(listener) != -1;
    }

    dispatch(event) {
      if (callbacks) {
        callbacks.forEach(callback => callback());
      }
    }
  };

  // MARK: - WebStorePrivateAPI
  const WebStoreResult = Object.freeze({
    "": "",
    ALREADY_INSTALLED: "already_installed",
    BLACKLISTED: "blacklisted",
    BLOCKED_BY_POLICY: "blocked_by_policy",
    BLOCKED_FOR_CHILD_ACCOUNT: "blocked_for_child_account",
    FEATURE_DISABLED: "feature_disabled",
    ICON_ERROR: "icon_error",
    INSTALL_ERROR: "install_error",
    INSTALL_IN_PROGRESS: "install_in_progress",
    INVALID_ICON_URL: "invalid_icon_url",
    INVALID_ID: "invalid_id",
    LAUNCH_IN_PROGRESS: "launch_in_progress",
    MANIFEST_ERROR: "manifest_error",
    MISSING_DEPENDENCIES: "missing_dependencies",
    SUCCESS: "success",
    UNKNOWN_ERROR: "unknown_error",
    UNSUPPORTED_EXTENSION_TYPE: "unsupported_extension_type",
    USER_CANCELLED: "user_cancelled",
    USER_GESTURE_REQUIRED: "user_gesture_required"
  });

  const WebStoreWebGLStatus = Object.freeze({
    WEBGL_ALLOWED: 'webgl_allowed',
    WEBGL_BLOCKED: 'webgl_blocked'
  });

  const WebStoreExtensionInstalledStatus = Object.freeze({
    BLACKLISTED: "blacklisted",
    BLOCKED_BY_POLICY: "blocked_by_policy",
    CAN_REQUEST: "can_request",
    CUSTODIAN_APPROVAL_REQUIRED: "custodian_approval_required",
    DISABLED: "disabled",
    ENABLED: "enabled",
    FORCE_INSTALLED: "force_installed",
    INSTALLABLE: "installable",
    REQUEST_PENDING: "request_pending",
    TERMINATED: "terminated"
  });

  Object.defineProperty(window, 'chrome', {
    enumerable: true,
    configurable: true,
    writable: true,
    value: {
      loadTimes: function() {
        return {
          commitLoadTime: new Date().getTime(),
          connectionInfo: "h3",
          finishDocumentLoadTime: new Date().getTime(),
          finishLoadTime: new Date().getTime(),
          firstPaintAfterLoadTime: 0,
          firstPaintTime: new Date().getTime(),
          navigationType: "Other",
          npnNegotiatedProtocol: "h3",
          requestTime: new Date().getTime(),
          startLoadTime: new Date().getTime(),
          wasAlternateProtocolAvailable: false,
          wasFetchedViaSpdy: true,
          wasNpnNegotiated: true
        };
      }
    }
  });

  Object.defineProperty(window.chrome, 'webstorePrivate', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
      Result: WebStoreResult,
      WebGLStatus: WebStoreWebGLStatus,
      ExtensionInstalledStatus: WebStoreExtensionInstalledStatus,

      // string, callback() [optional]
      install: function(expected_id, callback) {
        console.log("INSTALL: ", expected_id);
      },

      // dictionary { id: "...",
      //              manifest: "...",
      //              iconUrl: "[optional]",
      //              localizedName: "[optional]",
      //              locale: "[optional]",
      //              appInstallBubble: "[optional]",
      //              enableLauncher: "[optional]",
      //              authuser: "[optional]",
      //              esbAllowlist: "[optional]",
      //              ... [any] ...
      // },
      // callback(Result) [optional]
      beginInstallWithManifest3: function(details, callback) {
        console.log("BEGIN INSTALL WITH MANIFEST3: ", details);

        if (details.id.length !== 32) {
          return callback(WebStoreResult.INVALID_ID);
        }

        if (details.manifest.length < 1) {
          return callback(WebStoreResult.MANIFEST_ERROR);
        }

        postMessage('beginInstallWithManifest3', details).then(e => {
          callback(WebStoreResult.SUCCESS);
        })
        .catch(e => {
          callback(WebStoreResult.USER_CANCELLED);
        });
      },

      // string, callback() [optional]
      completeInstall: function(expected_id, callback) {
        console.log("COMPLETE INSTALL: ", expected_id);
      },

      // callback() [optional]
      enableAppLauncher: function(callback) {
        console.log("ENABLE APP LAUNCHER");
      },

      // callback(info: Dictionary {"login": "...."})
      getBrowserLogin: function(callback) {
        console.log("GET BROWSER LOGIN");
      },

      // callback(info: Dictionary {"login: "....")
      getStoreLogin: function(callback) {
        console.log("GET STORE LOGIN");
      },

      // string, callback() [optional]
      setStoreLogin: function(login, callback) {
        console.log("SET STORE LOGIN: ", login);
      },

      // callback(webgl_status: WebGlStatus)
      getWebGLStatus: function(callback) {
        console.log("GET WEBGL STATUS");
      },

      // callback(is_enabled: Bool)
      getIsLauncherEnabled: function(callback) {
        console.log("IS LAUNCHER ENABLED");
      },

      // callback(is_incognito_mode: Bool)
      isInIncognitoMode: function(callback) {
        console.log("IS INCOGNITO MODE");
        callback(false);
      },

      // callback(is_ephemeral_apps_enabled: Bool)
      getEphemeralAppsEnabled: function(callback) {
        console.log("EPHEMERAL APPS ENABLED");
        callback(false);
      },

      // string, callback(Result) [optional]
      launchEphemeralApp: function(id, callback) {
        console.log("LAUNCH EPHEMERAL APPS");
      },

      // string, callback(is_pending_approval: Bool)
      isPendingCustodianApproval: function(id, callback) {
        console.log("PENDING CUSTODIAL APPROVAL");
        callback(false);
      },

      // callback(referrerChain: String)
      getReferrerChain: function(callback) {
        console.log("REFERRER CHAIN");
        callback("EgIIAA==");
      },

      // string, string [optional], callback(status: ExtensionInstalledStatus)
      getExtensionStatus: function(id, callback) {
        console.log("EXTENSION STATUS");

        postMessage('getExtensionStatus', { extension_id: id}).then(e => {
          //callback(WebStoreExtensionInstalledStatus.INSTALLABLE);
          callback(e);
        })
        .catch(e => {
          callback(WebStoreExtensionInstalledStatus.TERMINATED);
          //callback(WebStoreExtensionInstalledStatus.INSTALLABLE);
        });
      },

      // string, callback(status: ExtensionInstalledStatus) [optional]
      requestExtension: function(id, callback) {
        console.log("REQUEST EXTENSION");
      }
    }
  });

  // MARK: - App
  const AppInstallState = Object.freeze({
    DISABLED: "disabled",
    INSTALLED: "installed",
    NOT_INSTALLED: "not_installed"
  });

  const AppRunningState = Object.freeze({
    CANNOT_RUN: "cannot_run",
    READY_TO_RUN: "ready_to_run",
    RUNNING: "running"
  });

  Object.defineProperty(window.chrome, 'app', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
      isInstalled: true,
      InstallState: AppInstallState,
      RunningState: AppRunningState,

      getIsInstalled: function() {
        return true;
      },

      installState: function(callback) {
        callback(AppInstallState.INSTALLED);
      },

      runningState: function() {
        return AppRunningState.CANNOT_RUN;
      },

      getDetails: function() {
        return {
            "app": {
                "launch": {
                    "web_url": "https://chrome.google.com/webstore"
                },
                "urls": [
                    "https://chrome.google.com/webstore"
                ]
            },
            "description": "Discover great apps, games, extensions and themes for Brave.",
            "icons": {
                "16": "webstore_icon_16.png",
                "128": "webstore_icon_128.png"
            },
            "id": "ahfgeienlihckogmohjhadlkjgocpleb",
            "key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCtl3tO0osjuzRsf6xtD2SKxPlTfuoy7AWoObysitBPvH5fE1NaAA1/2JkPWkVDhdLBWLaIBPYeXbzlHp3y4Vv/4XG+aN5qFE3z+1RU/NqkzVYHtIpVScf3DjTYtKVL66mzVGijSoAIwbFCC3LpGdaoe6Q1rSRDp76wR6jjFzsYwQIDAQAB",
            "name": "Web Store",
            "permissions": [
                "webstorePrivate",
                "management",
                "system.cpu",
                "system.display",
                "system.memory",
                "system.network",
                "system.storage"
            ],
            "version": "0.2"
        };
      }
    }
  });

  // MARK: - CSI
  Object.defineProperty(window.chrome, 'csi', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
      lonloadT: 1650903807361,
      pageT: 583430.65,
      startE: 1650903806990,
      tran: 16
    }
  });

  // MARK: - Extension
  Object.defineProperty(window.chrome, 'extension', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
//        lastError: { },
      inIncognitoContext: false,
      ViewType: { "TAB": "tab", "POPUP": "popup" },
    }
  });

  // MARK: - Management

  const ManagementLaunchType = Object.freeze({
    OPEN_AS_PINNED_TAB: 'OPEN_AS_PINNED_TAB',
    OPEN_AS_REGULAR_TAB: 'OPEN_AS_REGULAR_TAB',
    OPEN_AS_WINDOW: 'OPEN_AS_WINDOW',
    OPEN_FULL_SCREEN: 'OPEN_FULL_SCREEN'
  });

  const ManagementExtensionDisabledReason = Object.freeze({
    PERMISSIONS_INCREASE: 'permissions_increase',
    UNKNOWN: 'unknown'
  });

  const ManagementExtensionType = Object.freeze({
    EXTENSION: 'extension',
    HOSTED_APP: 'hosted_app',
    PACKAGED_APP: 'packaged_app',
    THEME: "theme",
    LOGIN_SCREEN_EXTENSION: 'login_screen_extension'
  });

  const ManagementExtensionInstallType = Object.freeze({
    ADMIN: 'admin',
    DEVELOPMENT: 'development',
    NORMAL: 'normal',
    OTHER: 'other',
    SIDELOAD: 'sideload'
  });

  const onInstalled = new EventEmitter();
  const onUninstalled = new EventEmitter();
  const onEnabled = new EventEmitter();
  const onDisabled = new EventEmitter();

  Object.defineProperty(window.chrome, 'management', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
      LaunchType: ManagementLaunchType,
      ExtensionDisabledReason: ManagementExtensionDisabledReason,
      ExtensionType: ManagementExtensionType,
      ExtensionInstallType: ManagementExtensionInstallType,

      // callback(result: [ExtensionInfo])
      getAll: function(callback) {
        console.log("GET ALL");
        callback([]);
        //setTimeout(callback([]), 2000);
      },

      // string, callback(result: [ExtensionInfo])
      get: function(id, callback) {
        console.log("GET");
        callback([])
      },

      // callback(result: [ExtensionInfo])
//      getSelf: function(callback) {
//        console.log("GET SELF");
//      },

      getPermissionWarningsById: function(id, callback) {
        console.log("GET PERMISSION WARNINGS BY ID");
      },

//      getPermissionWarningsByManifest: function(manifestStr, callback) {
//        console.log("GET PERMISSION WARNINGS BY MANIFEST");
//      },

      setEnabled: function(id, enabled, callback) {
        console.log("SET ENABELD");
      },

      uninstall: function(id, options, callback) {
        console.log("UNINSTALL");
      },

//      uninstallSelf: function(options, callback) {
//        console.log("UNINSTALL SELF");
//      },

      launchApp: function(id, callback) {
        console.log("LAUNCH APP");
      },

      createAppShortcut: function(id, callback) {
        console.log("CREATE APP SHORTCUT");
      },

      setLaunchType: function(id, launchType, callback) {
        console.log("SET APP LAUNCH TYPE");
      },

      generateAppForLink: function(url, title, callback) {
        console.log("GENERATE APP FOR LINK");
      },

      'onInstalled': onInstalled,
      'onUninstalled': onUninstalled,
      'onEnabled': onEnabled,
      'onDisabled': onDisabled
    }
  });

  // MARK: - Runtime

  Object.defineProperty(window.chrome, 'runtime', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
//        lastError: { },
      inIncognitoContext: false
    }
  });

  // MARK: - Dashboard Private

  const DashboardResult = Object.freeze({
    "": "",
    ICON_ERROR: "icon_error",
    INVALID_ICON_URL: "invalid_icon_url",
    INVALID_ID: "invalid_id",
    MANIFEST_ERROR: "manifest_error",
    UNKNOWN_ERROR: "unknown_error",
    USER_CANCELLED: "user_cancelled"
  });

  Object.defineProperty(window.chrome, 'dashboardPrivate', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
      Result: DashboardResult,
      showPermissionPromptForDelegatedInstall: function(options, details, callback) {
        console.log("showPermissionPromptForDelegatedInstall");
      }
    }
  });

  // MARK: - DOM
  Object.defineProperty(window.chrome, 'dom', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {
      openOrClosedShadowRoot: function(element) {
        console.log("openOrClosedShadowRoot");
      }
    }
  });

  // MARK: - System
});
