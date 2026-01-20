// ==UserScript==
// @name         IPA下载链接拦截器 - 终极版
// @namespace    http://tampermonkey.net/
// @version      3.0
// @description  通过修改页面HTML注入代码，100%拦截下载链接
// @author       You
// @match        https://app.ios80.com/*
// @match        http://app.ios80.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=ios80.com
// @grant        GM_xmlhttpRequest
// @grant        GM_setClipboard
// @grant        GM_notification
// @connect      *
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    console.log('='.repeat(70));
    console.log('[IPA拦截] 终极版脚本已加载');
    console.log('[IPA拦截] 运行时机: document-start');
    console.log('='.repeat(70));

    // ==================== 方法1：拦截HTML加载，注入代码 ====================
    
    // 保存原始的document.write
    const originalWrite = document.write;
    const originalWriteln = document.writeln;

    // 存储拦截到的数据
    window._ipaInterceptData = {
        shortLink: null,
        appId: null,
        token: null,
        downloadUrl: null
    };

    // 注入的代码（将在页面最开始执行）
    const injectedCode = `
    <script>
    console.log('[IPA拦截] 注入代码已执行');
    
    // 创建appInstall对象
    window.appInstall = {
        postMessage: function(data) {
            console.log('[IPA拦截] ✅ appInstall.postMessage 被调用');
            console.log('[IPA拦截] 参数:', data);
            
            // 存储数据
            window._ipaInterceptData = window._ipaInterceptData || {};
            window._ipaInterceptData.shortLink = data;
            
            // 触发自定义事件
            window.dispatchEvent(new CustomEvent('ipaIntercept', { 
                detail: { type: 'appInstall', data: data } 
            }));
            
            // 显示提示
            alert('🎯 拦截成功！\\nshortLink: ' + data + '\\n\\n请查看控制台和右上角悬浮窗');
            
            return true;
        }
    };
    
    window.appPreviewResource = {
        postMessage: function(data) {
            console.log('[IPA拦截] appPreviewResource.postMessage:', data);
            return true;
        }
    };
    
    // 模拟webkit接口
    if (!window.webkit) window.webkit = {};
    if (!window.webkit.messageHandlers) window.webkit.messageHandlers = {};
    window.webkit.messageHandlers.appInstall = {
        postMessage: function(data) {
            return window.appInstall.postMessage(data);
        }
    };
    
    console.log('[IPA拦截] ✅ appInstall 接口已注入');
    </script>
    `;

    // 拦截document.write，在第一次调用时注入代码
    let injected = false;
    document.write = function(...args) {
        if (!injected) {
            injected = true;
            originalWrite.call(document, injectedCode);
            console.log('[IPA拦截] ✅ 代码已通过document.write注入');
        }
        return originalWrite.apply(document, args);
    };

    document.writeln = function(...args) {
        if (!injected) {
            injected = true;
            originalWrite.call(document, injectedCode);
            console.log('[IPA拦截] ✅ 代码已通过document.writeln注入');
        }
        return originalWriteln.apply(document, args);
    };

    // ==================== 方法2：监听自定义事件 ====================
    
    window.addEventListener('ipaIntercept', function(e) {
        console.log('\n' + '='.repeat(70));
        console.log('[IPA拦截] 收到拦截事件:', e.detail);
        console.log('='.repeat(70) + '\n');

        const { type, data } = e.detail;

        if (type === 'appInstall') {
            handleAppInstall(data);
        }
    });

    // ==================== 方法3：直接在页面加载时注入 ====================
    
    // 创建script标签注入
    function injectScript() {
        const script = document.createElement('script');
        script.textContent = `
            (function() {
                console.log('[IPA拦截] Script标签注入代码已执行');
                
                // 如果appInstall还不存在，创建它
                if (!window.appInstall) {
                    window.appInstall = {
                        postMessage: function(data) {
                            console.log('[IPA拦截] ✅ appInstall.postMessage (Script注入)');
                            console.log('[IPA拦截] 参数:', data);
                            
                            window._ipaInterceptData = window._ipaInterceptData || {};
                            window._ipaInterceptData.shortLink = data;
                            
                            window.dispatchEvent(new CustomEvent('ipaIntercept', { 
                                detail: { type: 'appInstall', data: data } 
                            }));
                            
                            alert('🎯 拦截成功！\\nshortLink: ' + data);
                            
                            return true;
                        }
                    };
                    
                    window.appPreviewResource = {
                        postMessage: function(data) { return true; }
                    };
                    
                    console.log('[IPA拦截] ✅ appInstall 接口已创建 (Script注入)');
                }
            })();
        `;

        // 尝试插入到head最前面
        const insertScript = () => {
            if (document.head) {
                document.head.insertBefore(script, document.head.firstChild);
                console.log('[IPA拦截] ✅ Script标签已注入到head');
            } else if (document.documentElement) {
                document.documentElement.insertBefore(script, document.documentElement.firstChild);
                console.log('[IPA拦截] ✅ Script标签已注入到documentElement');
            } else {
                setTimeout(insertScript, 10);
            }
        };

        insertScript();
    }

    // 立即尝试注入
    injectScript();

    // 也在DOMContentLoaded时再次尝试
    document.addEventListener('DOMContentLoaded', injectScript);

    // ==================== 处理拦截到的数据 ====================
    
    function handleAppInstall(shortLink) {
        console.log('[IPA拦截] 处理shortLink:', shortLink);

        // 从URL获取参数
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');

        console.log('[IPA拦截] URL参数:', { shortLink, appId, token });

        // 显示通知
        GM_notification({
            title: '🎯 拦截成功',
            text: `shortLink: ${shortLink}`,
            timeout: 5000
        });

        // 构造API URL
        const apiUrl = `/${shortLink}/install?osName=iOS`;
        const fullUrl = window.location.origin + apiUrl;

        console.log('[IPA拦截] 请求API:', fullUrl);

        // 显示加载提示
        showResult('正在请求下载API...', '状态');

        // 请求API
        GM_xmlhttpRequest({
            method: 'POST',
            url: fullUrl,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
                'Referer': window.location.href
            },
            onload: function(response) {
                console.log('\n' + '='.repeat(70));
                console.log('[IPA拦截] API响应:');
                console.log('状态码:', response.status);
                console.log('响应体:', response.responseText);
                console.log('='.repeat(70) + '\n');

                showResult(`API响应 (${response.status})`, '状态');

                try {
                    const data = JSON.parse(response.responseText);
                    processAPIResponse(data);
                } catch (e) {
                    console.log('[IPA拦截] 响应不是JSON，尝试直接解析');
                    processTextResponse(response.responseText);
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] API请求失败:', error);
                showResult('API请求失败: ' + JSON.stringify(error), '错误');

                GM_notification({
                    title: '❌ 请求失败',
                    text: 'API请求出错',
                    timeout: 5000
                });
            }
        });
    }

    function processAPIResponse(data) {
        console.log('[IPA拦截] 处理JSON响应:', data);

        // 查找URL
        let found = false;

        function findURLs(obj, path = '') {
            for (let key in obj) {
                const value = obj[key];
                const currentPath = path ? `${path}.${key}` : key;

                if (typeof value === 'string') {
                    if (value.includes('.ipa') || 
                        value.includes('itms-services') || 
                        value.includes('.plist') ||
                        value.includes('manifest')) {

                        console.log(`[IPA拦截] 🎯 找到URL: ${currentPath} = ${value}`);
                        showResult(value, currentPath);
                        processURL(value);
                        found = true;
                    }
                } else if (typeof value === 'object' && value !== null) {
                    findURLs(value, currentPath);
                }
            }
        }

        findURLs(data);

        if (!found) {
            showResult(JSON.stringify(data, null, 2), 'API完整响应');
        }
    }

    function processTextResponse(text) {
        console.log('[IPA拦截] 处理文本响应');

        // 查找各种URL
        const patterns = [
            { regex: /https?:\/\/[^\s"'<>]+\.ipa/g, type: 'IPA链接' },
            { regex: /https?:\/\/[^\s"'<>]+\.plist/g, type: 'Plist链接' },
            { regex: /itms-services:\/\/[^\s"'<>]+/g, type: 'itms-services' }
        ];

        let found = false;

        patterns.forEach(({ regex, type }) => {
            const matches = text.match(regex);
            if (matches) {
                matches.forEach(url => {
                    console.log(`[IPA拦截] 🎯 找到${type}:`, url);
                    showResult(url, type);
                    processURL(url);
                    found = true;
                });
            }
        });

        if (!found) {
            showResult(text.substring(0, 500), '响应文本（前500字符）');
        }
    }

    function processURL(url) {
        if (url.includes('itms-services')) {
            // 提取manifest URL
            const match = url.match(/url=([^&]+)/);
            if (match) {
                const manifestUrl = decodeURIComponent(match[1]);
                console.log('[IPA拦截] Manifest URL:', manifestUrl);
                showResult(manifestUrl, 'Manifest URL');
                fetchManifest(manifestUrl);
            }
        } else if (url.includes('.ipa')) {
            // 直接IPA链接
            console.log('[IPA拦截] 🎉🎉🎉 IPA下载地址:', url);
            showResult(url, '🎉 IPA下载地址');

            GM_setClipboard(url);

            GM_notification({
                title: '🎉 成功！',
                text: 'IPA地址已复制到剪贴板',
                timeout: 10000
            });
        } else if (url.includes('.plist') || url.includes('manifest')) {
            // Manifest文件
            fetchManifest(url);
        }
    }

    function fetchManifest(url) {
        console.log('[IPA拦截] 获取Manifest:', url);
        showResult('正在获取Manifest...', '状态');

        GM_xmlhttpRequest({
            method: 'GET',
            url: url,
            onload: function(response) {
                console.log('[IPA拦截] Manifest内容:', response.responseText);

                const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                if (ipaMatch) {
                    const ipaUrl = ipaMatch[1];
                    console.log('[IPA拦截] 🎉🎉🎉 从Manifest提取IPA:', ipaUrl);

                    showResult(ipaUrl, '🎉 IPA下载地址（从Manifest）');

                    GM_setClipboard(ipaUrl);

                    GM_notification({
                        title: '🎉 成功！',
                        text: 'IPA地址已复制到剪贴板',
                        timeout: 10000
                    });
                } else {
                    showResult(response.responseText, 'Manifest内容');
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] 获取Manifest失败:', error);
                showResult('获取Manifest失败', '错误');
            }
        });
    }

    // ==================== UI显示 ====================
    
    function showResult(content, type) {
        // 等待body加载
        const display = () => {
            if (!document.body) {
                setTimeout(display, 100);
                return;
            }

            let resultBox = document.getElementById('ipa-result-box');

            if (!resultBox) {
                resultBox = document.createElement('div');
                resultBox.id = 'ipa-result-box';
                resultBox.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    width: 450px;
                    max-height: 80vh;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    border-radius: 15px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
                    z-index: 999999;
                    padding: 20px;
                    color: white;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    overflow-y: auto;
                `;

                resultBox.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                        <h3 style="margin: 0; font-size: 18px;">🎯 IPA拦截结果</h3>
                        <button onclick="this.parentElement.parentElement.remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 5px 10px; border-radius: 5px; cursor: pointer;">✕</button>
                    </div>
                    <div id="result-content"></div>
                `;

                document.body.appendChild(resultBox);
            }

            const resultContent = document.getElementById('result-content');
            if (resultContent) {
                const item = document.createElement('div');
                item.style.cssText = `
                    background: rgba(255,255,255,0.15);
                    padding: 12px;
                    border-radius: 8px;
                    margin-bottom: 10px;
                    word-break: break-all;
                `;

                const escapedContent = content.replace(/'/g, "\\'").replace(/"/g, '\\"');

                item.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                        <span style="font-size: 12px; opacity: 0.9;">${type}</span>
                        <button onclick="navigator.clipboard.writeText('${escapedContent}').then(() => alert('已复制')).catch(() => alert('复制失败'))" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 4px 10px; border-radius: 5px; cursor: pointer; font-size: 11px;">📋 复制</button>
                    </div>
                    <div style="font-size: 13px; font-family: monospace; max-height: 150px; overflow-y: auto;">${content}</div>
                `;

                resultContent.insertBefore(item, resultContent.firstChild);
            }
        };

        display();
    }

    console.log('[IPA拦截] ✅ 脚本初始化完成');
    console.log('[IPA拦截] 等待页面加载和用户操作...\n');

})();
