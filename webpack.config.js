const glob = require("glob");
const path = require("path");
const TerserPlugin = require('terser-webpack-plugin');

const __firefox__ = glob.sync("./Client/Frontend/UserContent/UserScripts/__firefox__.js")[0];

const AllFramesAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentStartSandboxed = glob.sync("./Client/Frontend/UserContent/UserScripts/Sandboxed/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js");
const AllFramesAtDocumentEndSandboxed = glob.sync("./Client/Frontend/UserContent/UserScripts/Sandboxed/AllFrames/AtDocumentEnd/*.js");

const MainFrameAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js");
const MainFrameAtDocumentStartSandboxed = glob.sync("./Client/Frontend/UserContent/UserScripts/Sandboxed/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEndSandboxed = glob.sync("./Client/Frontend/UserContent/UserScripts/Sandboxed/MainFrame/AtDocumentEnd/*.js");

//// Ensure the first script loaded at document start is __firefox__.js
//// since it defines the `window.__firefox__` global.
//// ----
//// Ensure the first script loaded at document end is __firefox__.js
//// since it also defines the `window.__firefox__` global because PDF
//// content does not execute user scripts designated to run at document
//// start for some reason. ¯\_(ツ)_/¯
[AllFramesAtDocumentStart,
 AllFramesAtDocumentEnd,
 AllFramesAtDocumentStartSandboxed,
 AllFramesAtDocumentEndSandboxed].forEach(e => {
  e.unshift(__firefox__);
  
  if (path.basename(e[0]) !== "__firefox__.js") {
    throw `ERROR: __firefox__.js is expected to be the first script in AllFrames script`
  }
});

module.exports = {
  mode: "production",
  entry: {
    AllFramesAtDocumentStart: AllFramesAtDocumentStart,
    AllFramesAtDocumentStartSandboxed: AllFramesAtDocumentStartSandboxed,
    AllFramesAtDocumentEnd: AllFramesAtDocumentEnd,
    AllFramesAtDocumentEndSandboxed: AllFramesAtDocumentEndSandboxed,
    MainFrameAtDocumentStart: MainFrameAtDocumentStart,
    MainFrameAtDocumentEnd: MainFrameAtDocumentEnd,
    MainFrameAtDocumentStartSandboxed: MainFrameAtDocumentStartSandboxed,
    MainFrameAtDocumentEndSandboxed: MainFrameAtDocumentEndSandboxed
  },
  // optimization: { minimize: false }, // use for debugging
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "Client/Assets")
  },
  optimization: {
    minimize: true,
    minimizer: [
      new TerserPlugin({
        extractComments: false,
        terserOptions: {
          format: {
            comments: false,
          },
        },
      }),
    ],
  },
  module: {
    rules: []
  },
  plugins: []
};
