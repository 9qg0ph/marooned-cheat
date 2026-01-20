// ==UserScript==
// @name         IPA下载 - 绕过点数限制版
// @namespace    http://tampermonkey.net/
// @version      4.0
// @description  拦截并修改API响应，绕过点数限制（仅供学习研究）
// @author       You
// @match        https://app.ios80.com/*
// @match        http://app.ios80.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=ios80.com
// @grant        GM_xmlhttpRequest
// @grant        GM_setClipboard
// @grant        GM_notification
// @grant        unsafeWindow
// @connect      *
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    console.log('='.repeat(70));
    console.log('[绕过限制] 脚本已加载 - 仅供学习研究');
    console.log('='.repeat(70));

    // ==================== 第一步：注入appInstall接口 ====================
    
    const injectedCode = `
    <script>
    (function() {
        console.log('[绕过限制] 注入代码已执行');
        
        // 创建appInstall对象
        window.appInstall = {
            postMessage: function(data) {
                console.log('[绕过限制] ✅ appInstall.postMessage 被调用');
                console.log('[绕过限制] shortLink:', data);
                
                window._ipaInterceptData = window._ipaInterceptData || {};
                window._ipaInterceptData.shortLink = data;
                
                window.dispatchEvent(new CustomEvent('ipaIntercept', { 
                    detail: { type: 'appInstall', data: data } 
                }));
                
                return true;
            }
        };
        
        window.appPreviewResource = {
            postMessage: function(data) { return true; }
        };
        
        console.log('[绕过限制] ✅ appInstall 接口已创建');
    })();
    </script>
    `;

    // 拦截document.write注入代码
    const originalWrite = document.write;
    let injected = false;
    
    document.write = function(...args) {
        if (!injected) {
            injected = true;
            originalWrite.call(document, injectedCode);
            console.log('[绕过限制] ✅ 代码已注入');
        }
        return originalWrite.apply(document, args);
    };

    // Script标签注入
    function injectScript() {
        const script = document.createElement('script');
        script.textContent = `
            (function() {
                if (!window.appInstall) {
                    window.appInstall = {
                        postMessage: function(data) {
                            console.log('[绕过限制] appInstall.postMessage:', data);
                            window._ipaInterceptData = window._ipaInterceptData || {};
                            window._ipaInterceptData.shortLink = data;
                            window.dispatchEvent(new CustomEvent('ipaIntercept', { 
                                detail: { type: 'appInstall', data: data } 
                            }));
                            return true;
                        }
                    };
                    window.appPreviewResource = { postMessage: function(data) { return true; } };
                }
            })();
        `;

        const insertScript = () => {
            if (document.head) {
                document.head.insertBefore(script, document.head.firstChild);
            } else if (document.documentElement) {
                document.documentElement.insertBefore(script, document.documentElement.firstChild);
            } else {
                setTimeout(insertScript, 10);
            }
        };

        insertScript();
    }

    injectScript();

    // ==================== 第二步：Hook XMLHttpRequest 拦截并修改响应 ====================
    
    console.log('[绕过限制] 开始Hook XMLHttpRequest...');

    // 保存原始方法
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSend = XMLHttpRequest.prototype.send;

    // Hook open方法
    XMLHttpRequest.prototype.open = function(method, url, ...args) {
        this._method = method;
        this._url = url;
        
        console.log(`[绕过限制] XHR请求: ${method} ${url}`);
        
        return originalOpen.apply(this, [method, url, ...args]);
    };

    // Hook send方法
    XMLHttpRequest.prototype.send = function(...args) {
        const xhr = this;
        
        // 如果是install API请求
        if (xhr._url && xhr._url.includes('/install')) {
            console.log('[绕过限制] 🎯 拦截到install API请求');
            
            // 保存原始的onreadystatechange
            const originalOnReadyStateChange = xhr.onreadystatechange;
            
            // 重写onreadystatechange
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    console.log('[绕过限制] API响应状态:', xhr.status);
                    console.log('[绕过限制] 原始响应:', xhr.responseText);
                    
                    try {
                        const originalResponse = JSON.parse(xhr.responseText);
                        console.log('[绕过限制] 原始响应JSON:', originalResponse);
                        
                        // 检查是否是点数不足错误
                        if (originalResponse.errorCode === -2 || 
                            (originalResponse.errorMessage && originalResponse.errorMessage.includes('点数不足'))) {
                            
                            console.log('[绕过限制] 🎯 检测到点数不足错误，尝试绕过...');
                            
                            // 方法1：尝试直接构造成功响应
                            const fakeSuccessResponse = {
                                code: 0,
                                errorCode: 0,
                                errorMessage: "success",
                                data: {
                                    downloadUrl: `itms-services://?action=download-manifest&url=https://app.ios80.com/${window._ipaInterceptData?.shortLink || '00TU'}/manifest.plist`
                                }
                            };
                            
                            console.log('[绕过限制] 🔧 构造的成功响应:', fakeSuccessResponse);
                            
                            // 修改responseText（这个方法可能不work，因为responseText是只读的）
                            // 但我们可以尝试修改response
                            Object.defineProperty(xhr, 'responseText', {
                                writable: true,
                                value: JSON.stringify(fakeSuccessResponse)
                            });
                            
                            Object.defineProperty(xhr, 'response', {
                                writable: true,
                                value: JSON.stringify(fakeSuccessResponse)
                            });
                            
                            console.log('[绕过限制] ✅ 响应已修改');
                            
                            // 显示修改后的响应
                            showResult(JSON.stringify(fakeSuccessResponse, null, 2), '🔧 修改后的响应');
                            
                            // 尝试直接处理下载
                            handleBypassDownload(window._ipaInterceptData?.shortLink);
                        }
                        
                    } catch (e) {
                        console.error('[绕过限制] 处理响应失败:', e);
                    }
                }
                
                // 调用原始的onreadystatechange
                if (originalOnReadyStateChange) {
                    return originalOnReadyStateChange.apply(this, arguments);
                }
            };
            
            // 也Hook addEventListener
            const originalAddEventListener = xhr.addEventListener;
            xhr.addEventListener = function(event, handler, ...args) {
                if (event === 'load' || event === 'readystatechange') {
                    const wrappedHandler = function(e) {
                        if (xhr.readyState === 4 && xhr._url && xhr._url.includes('/install')) {
                            console.log('[绕过限制] addEventListener触发');
                            
                            try {
                                const response = JSON.parse(xhr.responseText);
                                if (response.errorCode === -2) {
                                    console.log('[绕过限制] 在addEventListener中检测到点数不足');
                                    handleBypassDownload(window._ipaInterceptData?.shortLink);
                                }
                            } catch (e) {}
                        }
                        
                        return handler.apply(this, arguments);
                    };
                    
                    return originalAddEventListener.call(this, event, wrappedHandler, ...args);
                }
                
                return originalAddEventListener.apply(this, [event, handler, ...args]);
            };
        }
        
        return originalSend.apply(this, args);
    };

    // ==================== 第三步：Hook Fetch API ====================
    
    console.log('[绕过限制] 开始Hook Fetch API...');

    const originalFetch = window.fetch;
    
    window.fetch = function(...args) {
        const url = args[0];
        
        if (typeof url === 'string' && url.includes('/install')) {
            console.log('[绕过限制] 🎯 拦截到Fetch install请求:', url);
            
            return originalFetch.apply(this, args).then(response => {
                // 克隆响应以便读取
                const clonedResponse = response.clone();
                
                clonedResponse.json().then(data => {
                    console.log('[绕过限制] Fetch响应:', data);
                    
                    if (data.errorCode === -2) {
                        console.log('[绕过限制] Fetch检测到点数不足，尝试绕过...');
                        handleBypassDownload(window._ipaInterceptData?.shortLink);
                    }
                }).catch(e => {
                    console.log('[绕过限制] Fetch响应解析失败:', e);
                });
                
                return response;
            });
        }
        
        return originalFetch.apply(this, args);
    };

    // ==================== 第四步：绕过下载处理 ====================
    
    function handleBypassDownload(shortLink) {
        console.log('[绕过限制] 🚀 开始绕过下载流程...');
        console.log('[绕过限制] shortLink:', shortLink);
        
        if (!shortLink) {
            console.error('[绕过限制] shortLink为空，无法继续');
            showResult('shortLink为空，无法继续', '❌ 错误');
            return;
        }
        
        // 策略1：尝试直接访问manifest.plist
        const manifestUrls = [
            `https://app.ios80.com/${shortLink}/manifest.plist`,
            `https://app.ios80.com/api/manifest/${shortLink}.plist`,
            `https://app.ios80.com/download/${shortLink}/manifest.plist`,
            `https://cdn.ios80.com/${shortLink}/manifest.plist`
        ];
        
        console.log('[绕过限制] 尝试的Manifest URLs:', manifestUrls);
        showResult('正在尝试直接访问Manifest文件...', '🔍 状态');
        
        let successCount = 0;
        
        manifestUrls.forEach((manifestUrl, index) => {
            console.log(`[绕过限制] 尝试 ${index + 1}/${manifestUrls.length}: ${manifestUrl}`);
            
            GM_xmlhttpRequest({
                method: 'GET',
                url: manifestUrl,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15'
                },
                onload: function(response) {
                    console.log(`[绕过限制] Manifest ${index + 1} 响应:`, response.status);
                    
                    if (response.status === 200) {
                        console.log('[绕过限制] ✅ Manifest内容:', response.responseText);
                        
                        showResult(manifestUrl, `✅ Manifest URL ${index + 1}`);
                        
                        // 解析plist提取IPA URL
                        const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                        if (ipaMatch) {
                            const ipaUrl = ipaMatch[1];
                            console.log('[绕过限制] 🎉🎉🎉 找到IPA地址:', ipaUrl);
                            
                            showResult(ipaUrl, '🎉 IPA下载地址');
                            
                            GM_setClipboard(ipaUrl);
                            
                            GM_notification({
                                title: '🎉 绕过成功！',
                                text: 'IPA地址已复制到剪贴板',
                                timeout: 10000
                            });
                            
                            successCount++;
                        } else {
                            showResult(response.responseText, `Manifest ${index + 1} 内容`);
                        }
                    } else {
                        console.log(`[绕过限制] Manifest ${index + 1} 失败:`, response.status);
                    }
                },
                onerror: function(error) {
                    console.error(`[绕过限制] Manifest ${index + 1} 请求失败:`, error);
                }
            });
        });
        
        // 策略2：尝试直接构造IPA URL
        setTimeout(() => {
            if (successCount === 0) {
                console.log('[绕过限制] Manifest访问失败，尝试构造IPA URL...');
                
                const possibleIpaUrls = [
                    `https://app.ios80.com/download/${shortLink}.ipa`,
                    `https://cdn.ios80.com/apps/${shortLink}.ipa`,
                    `https://app.ios80.com/files/${shortLink}.ipa`,
                    `https://storage.ios80.com/${shortLink}.ipa`
                ];
                
                showResult(possibleIpaUrls.join('\n'), '🔍 可能的IPA URLs');
                
                console.log('[绕过限制] 可能的IPA URLs:', possibleIpaUrls);
                
                GM_notification({
                    title: '⚠️ 需要手动尝试',
                    text: '请查看悬浮窗中的可能URL',
                    timeout: 10000
                });
            }
        }, 3000);
        
        // 策略3：尝试不同的API端点
        const alternativeApis = [
            `https://app.ios80.com/api/v1/download/${shortLink}`,
            `https://app.ios80.com/api/v2/install/${shortLink}`,
            `https://app.ios80.com/${shortLink}/download?bypass=1`,
            `https://app.ios80.com/${shortLink}/install?osName=iOS&bypass=1`
        ];
        
        console.log('[绕过限制] 尝试替代API端点...');
        
        alternativeApis.forEach((apiUrl, index) => {
            GM_xmlhttpRequest({
                method: 'POST',
                url: apiUrl,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)'
                },
                onload: function(response) {
                    console.log(`[绕过限制] 替代API ${index + 1} 响应:`, response.status, response.responseText);
                    
                    if (response.status === 200) {
                        showResult(response.responseText, `替代API ${index + 1} 响应`);
                        
                        try {
                            const data = JSON.parse(response.responseText);
                            // 查找URL
                            findURLsInObject(data);
                        } catch (e) {
                            findURLsInText(response.responseText);
                        }
                    }
                },
                onerror: function(error) {
                    console.log(`[绕过限制] 替代API ${index + 1} 失败`);
                }
            });
        });
    }

    // ==================== 辅助函数 ====================
    
    function findURLsInObject(obj, path = '') {
        for (let key in obj) {
            const value = obj[key];
            const currentPath = path ? `${path}.${key}` : key;

            if (typeof value === 'string') {
                if (value.includes('.ipa') || 
                    value.includes('itms-services') || 
                    value.includes('.plist')) {
                    
                    console.log(`[绕过限制] 在 ${currentPath} 找到URL:`, value);
                    showResult(value, currentPath);
                    
                    if (value.includes('.ipa')) {
                        GM_setClipboard(value);
                        GM_notification({
                            title: '🎉 找到IPA',
                            text: '已复制到剪贴板',
                            timeout: 5000
                        });
                    }
                }
            } else if (typeof value === 'object' && value !== null) {
                findURLsInObject(value, currentPath);
            }
        }
    }

    function findURLsInText(text) {
        const patterns = [
            /https?:\/\/[^\s"'<>]+\.ipa/g,
            /https?:\/\/[^\s"'<>]+\.plist/g,
            /itms-services:\/\/[^\s"'<>]+/g
        ];

        patterns.forEach(regex => {
            const matches = text.match(regex);
            if (matches) {
                matches.forEach(url => {
                    console.log('[绕过限制] 在文本中找到URL:', url);
                    showResult(url, '文本中的URL');
                });
            }
        });
    }

    function showResult(content, type) {
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
                    width: 500px;
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
                        <h3 style="margin: 0; font-size: 18px;">🔓 绕过点数限制</h3>
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

                const escapedContent = String(content).replace(/'/g, "\\'").replace(/"/g, '\\"').replace(/\n/g, '\\n');

                item.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                        <span style="font-size: 12px; opacity: 0.9;">${type}</span>
                        <button onclick="navigator.clipboard.writeText('${escapedContent}').then(() => alert('已复制')).catch(() => alert('复制失败'))" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 4px 10px; border-radius: 5px; cursor: pointer; font-size: 11px;">📋 复制</button>
                    </div>
                    <div style="font-size: 13px; font-family: monospace; max-height: 200px; overflow-y: auto; white-space: pre-wrap;">${content}</div>
                `;

                resultContent.insertBefore(item, resultContent.firstChild);
            }
        };

        display();
    }

    // ==================== 监听拦截事件 ====================
    
    window.addEventListener('ipaIntercept', function(e) {
        console.log('[绕过限制] 收到拦截事件:', e.detail);
        
        const { data } = e.detail;
        
        GM_notification({
            title: '🎯 拦截成功',
            text: 'shortLink: ' + data,
            timeout: 3000
        });
        
        showResult(data, '📱 拦截到的shortLink');
        
        // 等待API响应后再处理
        setTimeout(() => {
            console.log('[绕过限制] 开始绕过流程...');
        }, 1000);
    });

    console.log('[绕过限制] ✅ 脚本初始化完成');
    console.log('[绕过限制] 所有Hook已设置');
    console.log('[绕过限制] ⚠️ 仅供学习研究使用\n');

})();
