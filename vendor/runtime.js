/*!
 * freecoding - 腾讯扣叮编辑器 webpack 4 兼容 runtime (jsonp 变体)
 * 与 webpack 4.x runtime 行为一致：
 *   - 处理 webpackJsonp.push([[chunkIds], {modules}, executeModules?])
 *   - 提供 __webpack_require__ 全套 API (.m/.c/.d/.r/.t/.n/.o/.p/.e/.f/.u)
 *   - 支持异步 chunk 动态加载 (.e / .f.j)
 * 说明：扣叮 5 个业务 chunk (id 2/3/4/5/6) 均不自洽（缺主 chunk），
 * 本 runtime 不预设入口；主 chunk 加载时会通过 data[2] 自动执行入口模块。
 */
(function () {
    // webpackBootstrap
    'use strict';
    var modules = {};
    var installedModules = {};
    var installedChunks = { main: 0 };
    var deferredModules = [];

    var root = typeof window !== 'undefined' ? window : (typeof globalThis !== 'undefined' ? globalThis : global);

    function __webpack_require__(moduleId) {
        if (installedModules[moduleId]) {
            return installedModules[moduleId].exports;
        }
        var module = installedModules[moduleId] = {
            i: moduleId,
            l: false,
            exports: {}
        };
        modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
        module.l = true;
        return module.exports;
    }

    __webpack_require__.m = modules;
    __webpack_require__.c = installedModules;
    __webpack_require__.d = function (exports, name, getter) {
        if (!__webpack_require__.o(exports, name)) {
            Object.defineProperty(exports, name, { enumerable: true, get: getter });
        }
    };
    __webpack_require__.r = function (exports) {
        if (typeof Symbol !== 'undefined' && Symbol.toStringTag) {
            Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
        }
        Object.defineProperty(exports, '__esModule', { value: true });
    };
    __webpack_require__.t = function (value, mode) {
        if (mode & 1) value = __webpack_require__(value);
        if (mode & 8) return value;
        if ((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
        var ns = Object.create(null);
        __webpack_require__.r(ns);
        Object.defineProperty(ns, 'default', { enumerable: true, value: value });
        if (mode & 2 && typeof value != 'string')
            for (var key in value)
                __webpack_require__.d(ns, key, function (key) { return value[key]; }.bind(null, key));
        return ns;
    };
    __webpack_require__.n = function (module) {
        var getter = module && module.__esModule ?
            function () { return module['default']; } :
            function () { return module; };
        __webpack_require__.d(getter, 'a', getter);
        return getter;
    };
    __webpack_require__.o = function (object, property) {
        return Object.prototype.hasOwnProperty.call(object, property);
    };
    __webpack_require__.p = '';
    __webpack_require__.u = function (chunkId) {
        return '' + chunkId + '.js';
    };
    __webpack_require__.f = {};
    __webpack_require__.e = function (chunkId) {
        return Promise.all(Object.keys(__webpack_require__.f).reduce(function (promises, key) {
            __webpack_require__.f[key](chunkId, promises);
            return promises;
        }, []));
    };
    __webpack_require__.g = root;

    var jsonpArray = root['webpackJsonp'] = root['webpackJsonp'] || [];
    var oldJsonpFunction = jsonpArray.push.bind(jsonpArray);
    jsonpArray.push = webpackJsonpCallback;
    jsonpArray = jsonpArray.slice();
    for (var i = 0; i < jsonpArray.length; i++) webpackJsonpCallback(jsonpArray[i]);
    var parentJsonpFunction = oldJsonpFunction;

    function webpackJsonpCallback(data) {
        var chunkIds = data[0];
        var moreModules = data[1];
        var executeModules = data[2];
        var moduleId, chunkId, i = 0, resolves = [], result;
        for (; i < chunkIds.length; i++) {
            chunkId = chunkIds[i];
            if (Object.prototype.hasOwnProperty.call(installedChunks, chunkId) && installedChunks[chunkId]) {
                resolves.push(installedChunks[chunkId][0]);
            }
            installedChunks[chunkId] = 0;
        }
        for (moduleId in moreModules) {
            if (Object.prototype.hasOwnProperty.call(moreModules, moduleId)) {
                modules[moduleId] = moreModules[moduleId];
            }
        }
        if (parentJsonpFunction) parentJsonpFunction(data);
        while (resolves.length) resolves.shift()();
        if (executeModules) {
            for (i = 0; i < executeModules.length; i++) {
                result = __webpack_require__(executeModules[i]);
            }
        }
        return result;
    }

    // 异步 chunk 加载器 (jsonp)
    __webpack_require__.f.j = function (chunkId, promises) {
        var installedChunkData = installedChunks[chunkId];
        if (installedChunkData !== 0) {
            if (installedChunkData) {
                promises.push(installedChunkData[2]);
            } else {
                var promise = new Promise(function (resolve, reject) {
                    installedChunkData = installedChunks[chunkId] = [resolve, reject];
                });
                promises.push(installedChunkData[2] = promise);
                var script = root.document.createElement('script');
                var onScriptComplete;
                script.charset = 'utf-8';
                script.timeout = 120;
                script.src = jsonpScriptSrc(chunkId);
                var error = new Error();
                onScriptComplete = function (event) {
                    script.onerror = script.onload = null;
                    clearTimeout(timeout);
                    var chunk = installedChunks[chunkId];
                    if (chunk !== 0) {
                        if (chunk) {
                            var errorType = event && (event.type === 'load' ? 'missing' : event.type);
                            var realSrc = event && event.target && event.target.src;
                            error.message = 'Loading chunk ' + chunkId + ' failed.\n(' + errorType + ': ' + realSrc + ')';
                            error.name = 'ChunkLoadError';
                            error.type = errorType;
                            error.request = realSrc;
                            chunk[1](error);
                        }
                        installedChunks[chunkId] = undefined;
                    }
                };
                var timeout = setTimeout(function () {
                    onScriptComplete({ type: 'timeout', target: script });
                }, 120000);
                script.onerror = script.onload = onScriptComplete;
                root.document.head.appendChild(script);
            }
        }
    };
    function jsonpScriptSrc(chunkId) {
        return __webpack_require__.p + __webpack_require__.u(chunkId);
    }

    // 挂载到全局，便于外部控制（加载主 chunk 后自动执行入口）
    root.__webpack_require__ = __webpack_require__;
    root.webpackJsonpCallback = webpackJsonpCallback;
    root.__webpack_modules__ = modules;
    root.__webpack_installed_chunks__ = installedChunks;
})();
