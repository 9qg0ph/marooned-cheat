// ==UserScript==
// @name         IPA下载链接拦截器 - 简化版
// @namespace    http://tampermonkey.net/
// @version      2.0
// @description  拦截并获取IPA真实下载地址
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

    console.log('='.repeat(60));
    console.log('[IPA拦截] 脚本已加载');
    console.log('='.repeat(60));

    // ==================== 第一步：模拟原生接口 ====================
    
    window.appInstall = {
        postMessage: function(shortLink) {
            console.log('\n' + '='.repeat(60));
            console.log('[IPA拦截] ✅ 拦截到 appInstall.postMessage');
            console.log('[IPA拦截] shortLink:', shortLink);
            console.log('='.repeat(60));

            // 显示通知
            GM_notification({
                title: '🎯 拦截成功',
                text: 'shortLink: ' + shortLink,
                timeout: 3000
            });

            // 立即请求下载API
            requestDownloadAPI(shortLink);

            return true;
        }
    };

    window.appPreviewResource = {
        postMessage: function(data) {
            return true;
        }
    };

    console.log('[IPA拦截] ✅ 原生接口模拟完成\n');

    // ==================== 第二步：请求下载API ====================
    
    function requestDownloadAPI(shortLink) {
        console.log('[IPA拦截] 开始请求下载API...');

        // 从URL获取参数
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');

        console.log('[IPA拦截] 参数:', { shortLink, appId, token });

        // 构造API URL（根据页面注释的代码推测）
        const apiUrl = `/${shortLink}/install?osName=iOS`;

        console.log('[IPA拦截] 请求URL:', window.location.origin + apiUrl);

        GM_xmlhttpRequest({
            method: 'POST',
            url: window.location.origin + apiUrl,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            onload: function(response) {
                console.log('\n' + '='.repeat(60));
                console.log('[IPA拦截] API响应状态:', response.status);
                console.log('[IPA拦截] API响应内容:', response.responseText);
                console.log('='.repeat(60) + '\n');

                try {
                    const data = JSON.parse(response.responseText);
                    console.log('[IPA拦截] 解析后的数据:', data);

                    // 处理响应数据
                    handleAPIResponse(data);

                } catch (e) {
                    console.error('[IPA拦截] JSON解析失败:', e);

                    // 尝试直接查找URL
                    findURLsInText(response.responseText);
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] API请求失败:', error);

                GM_notification({
                    title: '❌ 请求失败',
                    text: 'API请求出错',
                    timeout: 3000
                });
            }
        });
    }

    // ==================== 第三步：处理API响应 ====================
    
    function handleAPIResponse(data) {
        console.log('[IPA拦截] 处理API响应...');

        // 根据页面注释的代码，响应应该是一个URL字符串或包含URL的对象
        let downloadUrl = null;

        if (typeof data === 'string') {
            downloadUrl = data;
        } else if (data.url) {
            downloadUrl = data.url;
        } else if (data.data && data.data.url) {
            downloadUrl = data.data.url;
        } else if (data.downloadUrl) {
            downloadUrl = data.downloadUrl;
        }

        if (downloadUrl) {
            console.log('\n' + '='.repeat(60));
            console.log('[IPA拦截] 🎉 找到下载URL:');
            console.log(downloadUrl);
            console.log('='.repeat(60) + '\n');

            // 判断URL类型
            if (downloadUrl.includes('itms-services')) {
                // itms-services协议
                handleItmsServices(downloadUrl);
            } else if (downloadUrl.includes('.ipa')) {
                // 直接IPA链接
                handleDirectIPA(downloadUrl);
            } else if (downloadUrl.includes('.plist') || downloadUrl.includes('manifest')) {
                // manifest文件
                handleManifest(downloadUrl);
            } else {
                // 未知类型，显示给用户
                showResult(downloadUrl, '未知类型URL');
            }
        } else {
            console.log('[IPA拦截] ⚠️ 未在响应中找到下载URL');
            console.log('[IPA拦截] 完整响应:', data);

            // 递归查找所有可能的URL
            findURLsInObject(data);
        }
    }

    // ==================== 第四步：处理不同类型的URL ====================
    
    function handleItmsServices(url) {
        console.log('[IPA拦截] 处理itms-services协议...');

        // 提取manifest URL
        const match = url.match(/url=([^&]+)/);
        if (match) {
            const manifestUrl = decodeURIComponent(match[1]);
            console.log('[IPA拦截] Manifest URL:', manifestUrl);

            showResult(url, 'itms-services协议');
            handleManifest(manifestUrl);
        } else {
            showResult(url, 'itms-services协议（无法解析）');
        }
    }

    function handleDirectIPA(url) {
        console.log('[IPA拦截] 🎉🎉🎉 找到直接IPA下载链接!');

        showResult(url, 'IPA直接下载地址');

        // 自动复制
        GM_setClipboard(url);

        GM_notification({
            title: '🎉 成功！',
            text: 'IPA地址已复制到剪贴板',
            timeout: 10000
        });
    }

    function handleManifest(url) {
        console.log('[IPA拦截] 获取Manifest文件...');

        showResult(url, 'Manifest文件地址');

        GM_xmlhttpRequest({
            method: 'GET',
            url: url,
            onload: function(response) {
                console.log('[IPA拦截] Manifest内容:', response.responseText);

                // 解析plist，提取IPA URL
                const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                if (ipaMatch) {
                    const ipaUrl = ipaMatch[1];

                    console.log('\n' + '='.repeat(60));
                    console.log('[IPA拦截] 🎉🎉🎉 从Manifest中提取到IPA地址:');
                    console.log(ipaUrl);
                    console.log('='.repeat(60) + '\n');

                    handleDirectIPA(ipaUrl);
                } else {
                    console.log('[IPA拦截] ⚠️ 未在Manifest中找到IPA地址');
                    showResult(response.responseText, 'Manifest内容');
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] 获取Manifest失败:', error);
            }
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
                    value.includes('.plist') ||
                    value.includes('manifest')) {

                    console.log(`[IPA拦截] 在 ${currentPath} 找到URL:`, value);
                    showResult(value, currentPath);

                    if (value.includes('itms-services')) {
                        handleItmsServices(value);
                    } else if (value.includes('.ipa')) {
                        handleDirectIPA(value);
                    } else if (value.includes('.plist') || value.includes('manifest')) {
                        handleManifest(value);
                    }
                }
            } else if (typeof value === 'object' && value !== null) {
                findURLsInObject(value, currentPath);
            }
        }
    }

    function findURLsInText(text) {
        // 查找IPA链接
        const ipaMatches = text.match(/https?:\/\/[^\s"'<>]+\.ipa/g);
        if (ipaMatches) {
            ipaMatches.forEach(url => {
                console.log('[IPA拦截] 在文本中找到IPA:', url);
                handleDirectIPA(url);
            });
        }

        // 查找plist链接
        const plistMatches = text.match(/https?:\/\/[^\s"'<>]+\.plist/g);
        if (plistMatches) {
            plistMatches.forEach(url => {
                console.log('[IPA拦截] 在文本中找到Plist:', url);
                handleManifest(url);
            });
        }

        // 查找itms-services
        const itmsMatches = text.match(/itms-services:\/\/[^\s"'<>]+/g);
        if (itmsMatches) {
            itmsMatches.forEach(url => {
                console.log('[IPA拦截] 在文本中找到itms-services:', url);
                handleItmsServices(url);
            });
        }
    }

    function showResult(content, type) {
        // 创建结果显示框（如果不存在）
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
                    <h3 style="margin: 0; font-size: 18px;">🎯 IPA下载链接</h3>
                    <button onclick="this.parentElement.parentElement.remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 5px 10px; border-radius: 5px; cursor: pointer;">✕</button>
                </div>
                <div id="result-content"></div>
            `;

            // 等待body加载
            const addToBody = () => {
                if (document.body) {
                    document.body.appendChild(resultBox);
                } else {
                    setTimeout(addToBody, 100);
                }
            };
            addToBody();
        }

        // 添加结果项
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

            item.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                    <span style="font-size: 12px; opacity: 0.9;">${type}</span>
                    <button onclick="navigator.clipboard.writeText('${content.replace(/'/g, "\\'")}'); alert('已复制到剪贴板')" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 4px 10px; border-radius: 5px; cursor: pointer; font-size: 11px;">📋 复制</button>
                </div>
                <div style="font-size: 13px; font-family: monospace; max-height: 150px; overflow-y: auto;">${content}</div>
            `;

            resultContent.insertBefore(item, resultContent.firstChild);
        }
    }

    console.log('[IPA拦截] ✅ 脚本初始化完成');
    console.log('[IPA拦截] 等待用户点击下载按钮...\n');

})();
