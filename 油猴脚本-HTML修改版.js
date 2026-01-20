// ==UserScript==
// @name         IPA下载 - HTML修改版（终极解决方案）
// @namespace    http://tampermonkey.net/
// @version      7.0
// @description  直接修改页面HTML，在源头解决问题（仅供学习研究）
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
    console.log('[HTML修改版] 脚本开始执行');
    console.log('[HTML修改版] 准备拦截并修改页面HTML');
    console.log('='.repeat(70));

    // ==================== 方法1：拦截并修改HTML内容 ====================
    
    // 保存原始的Response构造函数
    const OriginalResponse = window.Response;
    
    // 重写Response构造函数
    window.Response = function(body, init) {
        if (typeof body === 'string' && body.includes('appInstall.postMessage')) {
            console.log('[HTML修改版] 🎯 检测到包含appInstall的HTML，开始修改...');
            
            // 在页面JavaScript之前注入我们的代码
            const injectedScript = `
<script>
console.log('[HTML修改版] 注入的脚本开始执行');

// 立即创建appInstall对象
window.appInstall = {
    postMessage: function(data) {
        console.log('[HTML修改版] ✅ appInstall.postMessage 被调用!');
        console.log('[HTML修改版] 参数:', data);
        
        // 立即显示成功提示
        alert('🎯 HTML修改版成功拦截！\\nshortLink: ' + data + '\\n\\n开始尝试绕过...');
        
        // 存储数据并开始绕过
        window._interceptedShortLink = data;
        
        // 延迟执行绕过逻辑，确保页面加载完成
        setTimeout(function() {
            window.startBypassAttempts && window.startBypassAttempts(data);
        }, 1000);
        
        return true;
    }
};

window.appPreviewResource = {
    postMessage: function(data) {
        console.log('[HTML修改版] appPreviewResource.postMessage:', data);
        return true;
    }
};

// 创建webkit接口
if (!window.webkit) window.webkit = {};
if (!window.webkit.messageHandlers) window.webkit.messageHandlers = {};
window.webkit.messageHandlers.appInstall = {
    postMessage: function(data) {
        return window.appInstall.postMessage(data);
    }
};

console.log('[HTML修改版] ✅ appInstall接口已创建');
</script>
`;
            
            // 在<head>标签后立即插入我们的脚本
            body = body.replace(/<head[^>]*>/i, '$&' + injectedScript);
            
            console.log('[HTML修改版] ✅ HTML已修改，appInstall接口已注入');
        }
        
        return new OriginalResponse(body, init);
    };

    // ==================== 方法2：拦截fetch请求 ====================
    
    const originalFetch = window.fetch;
    
    window.fetch = function(...args) {
        return originalFetch.apply(this, args).then(response => {
            const url = args[0];
            
            if (typeof url === 'string' && url.includes('ios80.com')) {
                console.log('[HTML修改版] 拦截到fetch请求:', url);
                
                // 克隆响应以便修改
                return response.text().then(text => {
                    if (text.includes('appInstall.postMessage')) {
                        console.log('[HTML修改版] 🎯 在fetch响应中发现appInstall，修改HTML...');
                        
                        const injectedScript = `
<script>
console.log('[HTML修改版] Fetch注入的脚本执行');
window.appInstall = {
    postMessage: function(data) {
        console.log('[HTML修改版] ✅ Fetch appInstall.postMessage:', data);
        alert('🎯 Fetch修改版成功！\\nshortLink: ' + data);
        window._interceptedShortLink = data;
        setTimeout(function() {
            window.startBypassAttempts && window.startBypassAttempts(data);
        }, 1000);
        return true;
    }
};
window.appPreviewResource = { postMessage: function(data) { return true; } };
</script>
`;
                        
                        const modifiedText = text.replace(/<head[^>]*>/i, '$&' + injectedScript);
                        
                        return new Response(modifiedText, {
                            status: response.status,
                            statusText: response.statusText,
                            headers: response.headers
                        });
                    }
                    
                    return new Response(text, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: response.headers
                    });
                });
            }
            
            return response;
        });
    };

    // ==================== 方法3：直接修改document.write ====================
    
    const originalDocumentWrite = document.write;
    const originalDocumentWriteln = document.writeln;
    
    let htmlBuffer = '';
    let injected = false;
    
    document.write = function(content) {
        htmlBuffer += content;
        
        if (!injected && content.includes('appInstall.postMessage')) {
            console.log('[HTML修改版] 🎯 在document.write中发现appInstall');
            
            const injectedScript = `
<script>
console.log('[HTML修改版] document.write注入执行');
window.appInstall = {
    postMessage: function(data) {
        console.log('[HTML修改版] ✅ document.write appInstall.postMessage:', data);
        alert('🎯 document.write修改成功！\\nshortLink: ' + data);
        window._interceptedShortLink = data;
        setTimeout(function() {
            window.startBypassAttempts && window.startBypassAttempts(data);
        }, 1000);
        return true;
    }
};
window.appPreviewResource = { postMessage: function(data) { return true; } };
</script>
`;
            
            // 在第一个script标签前注入
            content = content.replace(/<script/i, injectedScript + '<script');
            injected = true;
            
            console.log('[HTML修改版] ✅ document.write已修改');
        }
        
        return originalDocumentWrite.call(this, content);
    };
    
    document.writeln = function(content) {
        return document.write(content + '\n');
    };

    // ==================== 绕过尝试函数（在页面加载后执行）====================
    
    window.startBypassAttempts = function(shortLink) {
        console.log('[HTML修改版] 🚀 开始绕过尝试，shortLink:', shortLink);
        
        // 创建结果显示
        createResultDisplay();
        
        showResult('HTML修改版成功拦截！', '✅ 状态');
        showResult('shortLink: ' + shortLink, '📱 拦截数据');
        
        // 从URL获取参数
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId') || '1657';
        const token = urlParams.get('token') || 'A6B24C5FBE3C6A220BBE059AA54881C1';
        
        console.log('[HTML修改版] URL参数:', { shortLink, appId, token });
        
        // 开始各种绕过尝试
        tryDirectDownload(shortLink, appId, token);
    };
    
    function tryDirectDownload(shortLink, appId, token) {
        console.log('[HTML修改版] 开始直接下载尝试...');
        showResult('开始尝试直接下载...', '🔍 绕过尝试');
        
        // 最有希望的URL列表
        const downloadUrls = [
            // Manifest URLs
            `https://app.ios80.com/${shortLink}/manifest.plist`,
            `https://cdn.ios80.com/${shortLink}/manifest.plist`,
            `https://files.ios80.com/${shortLink}/manifest.plist`,
            
            // IPA直接下载
            `https://app.ios80.com/download/${shortLink}.ipa`,
            `https://cdn.ios80.com/apps/${shortLink}.ipa`,
            `https://files.ios80.com/${shortLink}.ipa`,
            
            // API端点
            `https://app.ios80.com/api/download/${shortLink}`,
            `https://api.ios80.com/download/${shortLink}`,
            
            // 特殊路径
            `https://app.ios80.com/internal/download/${shortLink}`,
            `https://app.ios80.com/admin/install/${shortLink}`
        ];
        
        downloadUrls.forEach((url, index) => {
            setTimeout(() => {
                console.log(`[HTML修改版] 尝试 ${index + 1}/${downloadUrls.length}:`, url);
                
                GM_xmlhttpRequest({
                    method: 'GET',
                    url: url,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
                        'Accept': '*/*',
                        'Referer': window.location.href
                    },
                    onload: function(response) {
                        console.log(`[HTML修改版] URL ${index + 1} 响应:`, response.status);
                        
                        if (response.status === 200) {
                            if (url.includes('.plist') && response.responseText.includes('<plist')) {
                                // 这是manifest文件
                                console.log('[HTML修改版] ✅ 找到manifest文件!');
                                showResult(url, `✅ Manifest文件 ${index + 1}`);
                                
                                // 解析IPA URL
                                const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                                if (ipaMatch) {
                                    const ipaUrl = ipaMatch[1];
                                    console.log('[HTML修改版] 🎉🎉🎉 找到IPA地址:', ipaUrl);
                                    
                                    showResult(ipaUrl, '🎉 IPA下载地址');
                                    
                                    GM_setClipboard(ipaUrl);
                                    
                                    GM_notification({
                                        title: '🎉 成功！',
                                        text: 'IPA地址已复制到剪贴板',
                                        timeout: 15000
                                    });
                                }
                            } else if (url.includes('.ipa')) {
                                // 这可能是IPA文件
                                const contentType = response.responseHeaders.toLowerCase();
                                if (contentType.includes('application/octet-stream') || 
                                    contentType.includes('application/zip')) {
                                    
                                    console.log('[HTML修改版] 🎉🎉🎉 找到IPA文件!');
                                    showResult(url, '🎉 IPA直接下载');
                                    
                                    GM_setClipboard(url);
                                    
                                    GM_notification({
                                        title: '🎉 找到IPA文件！',
                                        text: 'IPA地址已复制到剪贴板',
                                        timeout: 15000
                                    });
                                }
                            } else {
                                // 可能是API响应
                                showResult(response.responseText.substring(0, 500), `API响应 ${index + 1}`);
                                
                                try {
                                    const data = JSON.parse(response.responseText);
                                    findUrlsInResponse(data, `API ${index + 1}`);
                                } catch (e) {
                                    findUrlsInText(response.responseText, `响应 ${index + 1}`);
                                }
                            }
                        }
                    },
                    onerror: function(error) {
                        console.log(`[HTML修改版] URL ${index + 1} 失败`);
                    }
                });
            }, index * 300);
        });
    }
    
    // 在响应中查找URL
    function findUrlsInResponse(obj, source) {
        function findUrls(data, path = '') {
            for (let key in data) {
                const value = data[key];
                const currentPath = path ? `${path}.${key}` : key;

                if (typeof value === 'string') {
                    if (value.includes('.ipa') || 
                        value.includes('itms-services') || 
                        value.includes('.plist')) {
                        
                        console.log(`[HTML修改版] 在 ${source} 找到URL:`, value);
                        showResult(value, `🎯 ${source} - ${currentPath}`);
                        
                        if (value.includes('.ipa')) {
                            GM_setClipboard(value);
                            GM_notification({
                                title: '🎉 找到IPA链接',
                                text: '已复制到剪贴板',
                                timeout: 10000
                            });
                        }
                    }
                } else if (typeof value === 'object' && value !== null) {
                    findUrls(value, currentPath);
                }
            }
        }
        
        findUrls(obj);
    }

    // 在文本中查找URL
    function findUrlsInText(text, source) {
        const urlPatterns = [
            /https?:\/\/[^\s"'<>]+\.ipa/g,
            /https?:\/\/[^\s"'<>]+\.plist/g,
            /itms-services:\/\/[^\s"'<>]+/g
        ];
        
        urlPatterns.forEach(pattern => {
            const matches = text.match(pattern);
            if (matches) {
                matches.forEach(url => {
                    console.log(`[HTML修改版] 在 ${source} 文本中找到URL:`, url);
                    showResult(url, `🎯 ${source} - 文本`);
                });
            }
        });
    }

    // 创建结果显示
    function createResultDisplay() {
        const create = () => {
            if (!document.body) {
                setTimeout(create, 100);
                return;
            }

            if (document.getElementById('ipa-result-box')) return;

            const resultBox = document.createElement('div');
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
                    <h3 style="margin: 0; font-size: 18px;">🔧 HTML修改版</h3>
                    <button onclick="this.parentElement.parentElement.remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 5px 10px; border-radius: 5px; cursor: pointer;">✕</button>
                </div>
                <div id="result-content"></div>
            `;

            document.body.appendChild(resultBox);
        };

        create();
    }

    // 显示结果
    function showResult(content, type) {
        const display = () => {
            const resultContent = document.getElementById('result-content');
            if (!resultContent) {
                setTimeout(display, 100);
                return;
            }

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
        };

        display();
    }

    console.log('[HTML修改版] ✅ 脚本初始化完成');
    console.log('[HTML修改版] 已设置HTML拦截和修改');
    console.log('[HTML修改版] 等待页面加载...\n');

})();