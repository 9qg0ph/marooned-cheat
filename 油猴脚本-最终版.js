// ==UserScript==
// @name         IPA下载 - 最终版（最早注入）
// @namespace    http://tampermonkey.net/
// @version      6.0
// @description  使用最早注入时机确保成功（仅供学习研究）
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

// ==================== 立即执行，在任何页面代码之前 ====================

console.log('='.repeat(70));
console.log('[最终版] 脚本开始执行 - 最早时机');
console.log('[最终版] 立即创建appInstall接口');
console.log('='.repeat(70));

// 立即创建appInstall对象，不等待任何事件
window.appInstall = {
    postMessage: function(data) {
        console.log('[最终版] ✅ appInstall.postMessage 被调用!');
        console.log('[最终版] 参数:', data);
        
        // 立即显示成功提示
        alert('🎯 成功拦截！\nshortLink: ' + data + '\n\n开始尝试绕过...');
        
        // 存储数据
        window._interceptedShortLink = data;
        
        // 立即开始绕过尝试
        setTimeout(() => startBypassAttempts(data), 100);
        
        return true;
    }
};

window.appPreviewResource = {
    postMessage: function(data) {
        console.log('[最终版] appPreviewResource.postMessage:', data);
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

console.log('[最终版] ✅ appInstall接口已创建');
console.log('[最终版] window.appInstall:', window.appInstall);

// ==================== 绕过尝试函数 ====================

function startBypassAttempts(shortLink) {
    console.log('[最终版] 🚀 开始绕过尝试，shortLink:', shortLink);
    
    // 创建结果显示
    createResultDisplay();
    
    showResult('开始绕过尝试...', '🚀 状态');
    showResult('shortLink: ' + shortLink, '📱 拦截数据');
    
    // 从URL获取参数
    const urlParams = new URLSearchParams(window.location.search);
    const appId = urlParams.get('appId') || '1657';
    const token = urlParams.get('token') || 'A6B24C5FBE3C6A220BBE059AA54881C1';
    
    console.log('[最终版] URL参数:', { shortLink, appId, token });
    
    // 策略1：直接尝试manifest URLs（最有希望）
    tryDirectManifestUrls(shortLink, appId, token);
    
    // 策略2：尝试IPA直接下载
    setTimeout(() => tryDirectIpaUrls(shortLink, appId, token), 1000);
    
    // 策略3：尝试不同的API端点
    setTimeout(() => tryAlternativeApis(shortLink, appId, token), 2000);
    
    // 策略4：尝试绕过token验证
    setTimeout(() => tryTokenBypass(shortLink, appId), 3000);
}

// 策略1：直接尝试manifest URLs
function tryDirectManifestUrls(shortLink, appId, token) {
    console.log('[最终版] 策略1: 尝试直接manifest URLs...');
    showResult('尝试直接访问manifest文件...', '🔍 策略1');
    
    const manifestUrls = [
        `https://app.ios80.com/${shortLink}/manifest.plist`,
        `https://app.ios80.com/api/manifest/${shortLink}.plist`,
        `https://app.ios80.com/download/${shortLink}/manifest.plist`,
        `https://cdn.ios80.com/${shortLink}/manifest.plist`,
        `https://files.ios80.com/${shortLink}/manifest.plist`,
        `https://storage.ios80.com/manifest/${shortLink}.plist`,
        `https://app.ios80.com/apps/${shortLink}/manifest.plist`,
        `https://app.ios80.com/ipa/${shortLink}/manifest.plist`
    ];
    
    manifestUrls.forEach((url, index) => {
        setTimeout(() => {
            console.log(`[最终版] 尝试manifest ${index + 1}:`, url);
            
            GM_xmlhttpRequest({
                method: 'GET',
                url: url,
                headers: {
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
                    'Accept': 'application/x-plist, */*',
                    'Referer': window.location.href
                },
                onload: function(response) {
                    console.log(`[最终版] Manifest ${index + 1} 响应:`, response.status);
                    
                    if (response.status === 200 && response.responseText.includes('<plist')) {
                        console.log('[最终版] ✅ 找到有效的manifest!');
                        showResult(url, `✅ 有效的Manifest URL ${index + 1}`);
                        
                        // 解析plist
                        const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                        if (ipaMatch) {
                            const ipaUrl = ipaMatch[1];
                            console.log('[最终版] 🎉🎉🎉 找到IPA地址:', ipaUrl);
                            
                            showResult(ipaUrl, '🎉 IPA下载地址');
                            
                            GM_setClipboard(ipaUrl);
                            
                            GM_notification({
                                title: '🎉 成功！',
                                text: 'IPA地址已复制到剪贴板',
                                timeout: 15000
                            });
                            
                            // 尝试直接下载验证
                            verifyIpaUrl(ipaUrl);
                        } else {
                            showResult(response.responseText.substring(0, 500), `Manifest ${index + 1} 内容`);
                        }
                    } else if (response.status !== 404) {
                        console.log(`[最终版] Manifest ${index + 1} 状态:`, response.status);
                        showResult(`状态: ${response.status}`, `Manifest ${index + 1} 响应`);
                    }
                },
                onerror: function(error) {
                    console.log(`[最终版] Manifest ${index + 1} 失败`);
                }
            });
        }, index * 200);
    });
}

// 策略2：尝试IPA直接下载
function tryDirectIpaUrls(shortLink, appId, token) {
    console.log('[最终版] 策略2: 尝试IPA直接下载...');
    showResult('尝试IPA直接下载...', '🔍 策略2');
    
    const ipaUrls = [
        `https://app.ios80.com/download/${shortLink}.ipa`,
        `https://cdn.ios80.com/apps/${shortLink}.ipa`,
        `https://files.ios80.com/${shortLink}.ipa`,
        `https://storage.ios80.com/${shortLink}.ipa`,
        `https://app.ios80.com/ipa/${shortLink}.ipa`,
        `https://app.ios80.com/files/${appId}.ipa`,
        `https://cdn.ios80.com/ipa/${appId}.ipa`,
        `https://app.ios80.com/apps/woduzi.ipa`,
        `https://app.ios80.com/apps/我独自生活.ipa`
    ];
    
    ipaUrls.forEach((url, index) => {
        setTimeout(() => {
            console.log(`[最终版] 尝试IPA ${index + 1}:`, url);
            
            GM_xmlhttpRequest({
                method: 'HEAD', // 使用HEAD请求检查文件是否存在
                url: url,
                onload: function(response) {
                    console.log(`[最终版] IPA ${index + 1} 响应:`, response.status);
                    
                    if (response.status === 200) {
                        const contentType = response.responseHeaders.toLowerCase();
                        if (contentType.includes('application/octet-stream') || 
                            contentType.includes('application/zip') ||
                            contentType.includes('application/x-ios-app')) {
                            
                            console.log('[最终版] 🎉🎉🎉 找到IPA文件!');
                            showResult(url, `🎉 IPA直接下载地址 ${index + 1}`);
                            
                            GM_setClipboard(url);
                            
                            GM_notification({
                                title: '🎉 找到IPA文件！',
                                text: 'IPA地址已复制到剪贴板',
                                timeout: 15000
                            });
                        }
                    }
                },
                onerror: function(error) {
                    console.log(`[最终版] IPA ${index + 1} 失败`);
                }
            });
        }, index * 300);
    });
}

// 策略3：尝试不同的API端点
function tryAlternativeApis(shortLink, appId, token) {
    console.log('[最终版] 策略3: 尝试替代API端点...');
    showResult('尝试替代API端点...', '🔍 策略3');
    
    const apiEndpoints = [
        `https://app.ios80.com/api/download/${shortLink}`,
        `https://app.ios80.com/api/v1/install/${shortLink}`,
        `https://app.ios80.com/api/v2/download/${appId}`,
        `https://api.ios80.com/download/${shortLink}`,
        `https://api.ios80.com/v1/app/${appId}/download`,
        `https://app.ios80.com/internal/download/${shortLink}`,
        `https://app.ios80.com/admin/install/${shortLink}`,
        `https://app.ios80.com/debug/download/${shortLink}`
    ];
    
    apiEndpoints.forEach((url, index) => {
        setTimeout(() => {
            console.log(`[最终版] 尝试API ${index + 1}:`, url);
            
            GM_xmlhttpRequest({
                method: 'GET',
                url: url,
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'X-App-Id': appId,
                    'X-Short-Link': shortLink,
                    'User-Agent': 'iOS-App-Downloader/1.0'
                },
                onload: function(response) {
                    console.log(`[最终版] API ${index + 1} 响应:`, response.status);
                    
                    if (response.status === 200) {
                        showResult(response.responseText, `API ${index + 1} 响应`);
                        
                        try {
                            const data = JSON.parse(response.responseText);
                            findUrlsInResponse(data, `API ${index + 1}`);
                        } catch (e) {
                            findUrlsInText(response.responseText, `API ${index + 1}`);
                        }
                    }
                },
                onerror: function(error) {
                    console.log(`[最终版] API ${index + 1} 失败`);
                }
            });
        }, index * 400);
    });
}

// 策略4：尝试绕过token验证
function tryTokenBypass(shortLink, appId) {
    console.log('[最终版] 策略4: 尝试绕过token验证...');
    showResult('尝试绕过token验证...', '🔍 策略4');
    
    const bypassTokens = [
        'BYPASS_TOKEN_FOR_TESTING_ONLY',
        'ADMIN_SUPER_SECRET_TOKEN_2024',
        'DEFAULT_DOWNLOAD_TOKEN_BYPASS',
        '00000000000000000000000000000000',
        'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
        'TEST_TOKEN_NO_VERIFICATION_REQ'
    ];
    
    bypassTokens.forEach((testToken, index) => {
        setTimeout(() => {
            const testUrl = `https://app.ios80.com/${shortLink}/install?osName=iOS&appId=${appId}&token=${testToken}`;
            
            console.log(`[最终版] 尝试绕过token ${index + 1}:`, testToken);
            
            GM_xmlhttpRequest({
                method: 'POST',
                url: testUrl,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${testToken}`,
                    'X-Bypass': '1',
                    'X-Admin': '1'
                },
                onload: function(response) {
                    if (response.status === 200) {
                        try {
                            const data = JSON.parse(response.responseText);
                            if (data.errorCode !== -2) {
                                console.log('[最终版] 🎉 Token绕过成功!');
                                showResult(`Token: ${testToken}\n响应: ${response.responseText}`, `✅ 成功的绕过Token ${index + 1}`);
                                findUrlsInResponse(data, `绕过Token ${index + 1}`);
                            }
                        } catch (e) {}
                    }
                }
            });
        }, index * 500);
    });
}

// 验证IPA URL是否有效
function verifyIpaUrl(ipaUrl) {
    console.log('[最终版] 验证IPA URL:', ipaUrl);
    
    GM_xmlhttpRequest({
        method: 'HEAD',
        url: ipaUrl,
        onload: function(response) {
            if (response.status === 200) {
                const contentLength = response.responseHeaders.match(/content-length:\s*(\d+)/i);
                if (contentLength) {
                    const size = parseInt(contentLength[1]);
                    const sizeMB = (size / 1024 / 1024).toFixed(2);
                    
                    showResult(`文件大小: ${sizeMB} MB\n状态: 可下载`, '✅ IPA文件验证');
                    
                    GM_notification({
                        title: '✅ IPA文件验证成功',
                        text: `文件大小: ${sizeMB} MB`,
                        timeout: 10000
                    });
                }
            } else {
                showResult(`状态码: ${response.status}`, '❌ IPA文件验证失败');
            }
        }
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
                    
                    console.log(`[最终版] 在 ${source} 找到URL:`, value);
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
                console.log(`[最终版] 在 ${source} 文本中找到URL:`, url);
                showResult(url, `🎯 ${source} - 文本`);
            });
        }
    });
}

// 创建结果显示
function createResultDisplay() {
    // 等待body加载
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
                <h3 style="margin: 0; font-size: 18px;">🎯 最终版绕过尝试</h3>
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

console.log('[最终版] ✅ 脚本初始化完成');
console.log('[最终版] appInstall接口已就绪');
console.log('[最终版] 等待用户点击下载按钮...\n');