// ==UserScript==
// @name         拦截IPA下载链接 - 我独自生活
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  拦截并显示IPA真实下载地址，绕过激活码验证
// @author       You
// @match        https://app.ios80.com/*
// @match        http://app.ios80.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=ios80.com
// @grant        GM_xmlhttpRequest
// @grant        GM_setClipboard
// @grant        GM_notification
// @connect      *
// @run-at       document-start
// @require      https://code.jquery.com/jquery-3.6.0.min.js
// ==/UserScript==

(function() {
    'use strict';

    console.log('[IPA拦截] 脚本已加载 - 运行时机: document-start');

    // ==================== 立即模拟原生应用接口（在页面脚本执行前）====================
    // 必须在 document-start 阶段注入，否则页面脚本会报错

    console.log('[IPA拦截] 注入原生应用接口模拟...');

    // 模拟 appInstall 对象
    window.appInstall = {
        postMessage: function(data) {
            console.log('[IPA拦截] ✅ appInstall.postMessage 被调用:', data);
            console.log('[IPA拦截] 数据类型:', typeof data);

            // 显示通知
            setTimeout(() => {
                GM_notification({
                    title: '🎯 拦截到下载请求',
                    text: 'appInstall.postMessage: ' + data,
                    timeout: 5000
                });
            }, 100);

            // 存储到全局变量供后续使用
            if (!window._interceptedData) {
                window._interceptedData = [];
            }
            window._interceptedData.push({
                type: 'appInstall',
                data: data,
                timestamp: new Date().toISOString()
            });

            // 尝试解析shortLink并获取下载链接
            handleAppInstallData(data);

            return true;
        }
    };

    // 模拟 appPreviewResource 对象
    window.appPreviewResource = {
        postMessage: function(data) {
            console.log('[IPA拦截] appPreviewResource.postMessage 被调用:', data);
            return true;
        }
    };

    // 模拟 webkit.messageHandlers（iOS WKWebView接口）
    if (!window.webkit) {
        window.webkit = {};
    }
    if (!window.webkit.messageHandlers) {
        window.webkit.messageHandlers = {};
    }

    window.webkit.messageHandlers.appInstall = {
        postMessage: function(data) {
            console.log('[IPA拦截] webkit.messageHandlers.appInstall.postMessage:', data);
            return window.appInstall.postMessage(data);
        }
    };

    console.log('[IPA拦截] ✅ 原生接口模拟完成');
    console.log('[IPA拦截] window.appInstall:', window.appInstall);

    // 处理appInstall数据
    function handleAppInstallData(data) {
        console.log('[IPA拦截] 处理appInstall数据:', data);

        // 从当前URL获取参数
        const urlParams = new URLSearchParams(window.location.search);
        const appId = urlParams.get('appId');
        const token = urlParams.get('token');
        const shortLink = window.location.pathname.split('/')[1]; // 例如 /00TU

        console.log('[IPA拦截] URL参数:', {
            shortLink: shortLink,
            appId: appId,
            token: token
        });

        // 构造可能的API端点
        const apiEndpoints = [
            `https://app.ios80.com/${shortLink}/install?osName=iOS`,
            `https://app.ios80.com/api/v1/app/${appId}/download?token=${token}`,
            `https://app.ios80.com/api/install?shortLink=${shortLink}&appId=${appId}&token=${token}`,
            `https://app.ios80.com/${data}` // 如果data是路径
        ];

        console.log('[IPA拦截] 尝试的API端点:', apiEndpoints);

        // 尝试每个端点
        apiEndpoints.forEach(url => {
            console.log('[IPA拦截] 请求:', url);

            GM_xmlhttpRequest({
                method: 'POST',
                url: url,
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
                    'Referer': window.location.href
                },
                onload: function(response) {
                    console.log('[IPA拦截] 响应状态:', response.status);
                    console.log('[IPA拦截] 响应内容:', response.responseText);

                    try {
                        // 尝试解析JSON
                        const json = JSON.parse(response.responseText);
                        console.log('[IPA拦截] JSON响应:', json);

                        // 查找下载链接
                        findDownloadLinks(json);
                    } catch (e) {
                        // 不是JSON，直接查找URL
                        findUrlsInText(response.responseText);
                    }
                },
                onerror: function(error) {
                    console.error('[IPA拦截] 请求失败:', url, error);
                }
            });
        });
    }

    // 在JSON中查找下载链接
    function findDownloadLinks(obj, path = '') {
        for (let key in obj) {
            const value = obj[key];
            const currentPath = path ? `${path}.${key}` : key;

            if (typeof value === 'string') {
                if (value.includes('.ipa') ||
                    value.includes('itms-services') ||
                    value.includes('manifest') ||
                    value.includes('.plist')) {

                    console.log('[IPA拦截] 🎯 找到下载链接:', currentPath, '=', value);

                    GM_notification({
                        title: '🎉 找到下载链接',
                        text: value.substring(0, 50) + '...',
                        timeout: 10000
                    });

                    // 存储链接
                    if (!window._downloadLinks) {
                        window._downloadLinks = [];
                    }
                    window._downloadLinks.push({
                        path: currentPath,
                        url: value,
                        timestamp: new Date().toISOString()
                    });

                    // 如果是manifest URL，获取其内容
                    if (value.includes('.plist') || value.includes('manifest')) {
                        fetchManifestContent(value);
                    }
                }
            } else if (typeof value === 'object' && value !== null) {
                findDownloadLinks(value, currentPath);
            }
        }
    }

    // 在文本中查找URL
    function findUrlsInText(text) {
        // 查找IPA链接
        const ipaMatches = text.match(/https?:\/\/[^\s"'<>]+\.ipa/g);
        if (ipaMatches) {
            ipaMatches.forEach(url => {
                console.log('[IPA拦截] 🎯 找到IPA链接:', url);
                GM_notification({
                    title: '🎉 找到IPA链接',
                    text: url,
                    timeout: 10000
                });
            });
        }

        // 查找itms-services链接
        const itmsMatches = text.match(/itms-services:\/\/\?action=download-manifest&url=([^"'&\s]+)/g);
        if (itmsMatches) {
            itmsMatches.forEach(match => {
                console.log('[IPA拦截] 🎯 找到itms-services:', match);

                const urlMatch = match.match(/url=([^&]+)/);
                if (urlMatch) {
                    const manifestUrl = decodeURIComponent(urlMatch[1]);
                    console.log('[IPA拦截] Manifest URL:', manifestUrl);
                    fetchManifestContent(manifestUrl);
                }
            });
        }

        // 查找plist链接
        const plistMatches = text.match(/https?:\/\/[^\s"'<>]+\.plist/g);
        if (plistMatches) {
            plistMatches.forEach(url => {
                console.log('[IPA拦截] 🎯 找到Plist链接:', url);
                fetchManifestContent(url);
            });
        }
    }

    // 获取manifest文件内容
    function fetchManifestContent(url) {
        console.log('[IPA拦截] 获取Manifest文件:', url);

        GM_xmlhttpRequest({
            method: 'GET',
            url: url,
            onload: function(response) {
                console.log('[IPA拦截] Manifest内容:', response.responseText);

                // 解析plist，提取IPA URL
                const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                if (ipaMatch) {
                    const ipaUrl = ipaMatch[1];
                    console.log('[IPA拦截] 🎉🎉🎉 找到IPA下载地址:', ipaUrl);

                    GM_notification({
                        title: '🎉🎉🎉 成功！',
                        text: 'IPA下载地址: ' + ipaUrl,
                        timeout: 20000
                    });

                    // 自动复制到剪贴板
                    GM_setClipboard(ipaUrl);

                    GM_notification({
                        title: '📋 已复制',
                        text: 'IPA地址已复制到剪贴板',
                        timeout: 5000
                    });
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] 获取Manifest失败:', error);
            }
        });
    }


    // 存储拦截到的下载链接
    let downloadLinks = [];

    // 创建悬浮窗显示拦截到的链接
    function createFloatingPanel() {
        const panel = document.createElement('div');
        panel.id = 'ipa-intercept-panel';
        panel.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            width: 400px;
            max-height: 600px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            z-index: 999999;
            padding: 20px;
            color: white;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            overflow-y: auto;
        `;

        panel.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                <h3 style="margin: 0; font-size: 18px;">🎯 IPA下载链接拦截器</h3>
                <button id="close-panel" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 5px 10px; border-radius: 5px; cursor: pointer;">✕</button>
            </div>
            <div id="link-container" style="background: rgba(255,255,255,0.1); border-radius: 8px; padding: 15px; margin-bottom: 10px;">
                <p style="margin: 0; font-size: 14px; opacity: 0.9;">等待拦截下载链接...</p>
            </div>
            <div style="display: flex; gap: 10px;">
                <button id="copy-all" style="flex: 1; background: rgba(255,255,255,0.2); border: none; color: white; padding: 10px; border-radius: 8px; cursor: pointer; font-size: 14px;">📋 复制所有链接</button>
                <button id="bypass-activation" style="flex: 1; background: #4CAF50; border: none; color: white; padding: 10px; border-radius: 8px; cursor: pointer; font-size: 14px;">🔓 绕过激活</button>
            </div>
        `;

        document.body.appendChild(panel);

        // 关闭按钮
        document.getElementById('close-panel').addEventListener('click', () => {
            panel.style.display = 'none';
        });

        // 复制所有链接
        document.getElementById('copy-all').addEventListener('click', () => {
            if (downloadLinks.length > 0) {
                const allLinks = downloadLinks.join('\n');
                GM_setClipboard(allLinks);
                GM_notification({
                    title: '✅ 复制成功',
                    text: `已复制 ${downloadLinks.length} 个链接到剪贴板`,
                    timeout: 3000
                });
            } else {
                GM_notification({
                    title: '⚠️ 没有链接',
                    text: '还没有拦截到任何下载链接',
                    timeout: 3000
                });
            }
        });

        // 绕过激活按钮
        document.getElementById('bypass-activation').addEventListener('click', () => {
            bypassActivation();
        });

        return panel;
    }

    // 更新悬浮窗内容
    function updatePanel(link, type) {
        const container = document.getElementById('link-container');
        if (!container) return;

        downloadLinks.push(link);

        const linkItem = document.createElement('div');
        linkItem.style.cssText = `
            background: rgba(255,255,255,0.15);
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 10px;
            word-break: break-all;
        `;

        linkItem.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px;">
                <span style="font-size: 12px; opacity: 0.8;">${type}</span>
                <button class="copy-btn" data-link="${link}" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 3px 8px; border-radius: 4px; cursor: pointer; font-size: 11px;">复制</button>
            </div>
            <div style="font-size: 13px; font-family: monospace;">${link}</div>
        `;

        if (container.querySelector('p')) {
            container.innerHTML = '';
        }

        container.appendChild(linkItem);

        // 复制单个链接
        linkItem.querySelector('.copy-btn').addEventListener('click', function() {
            GM_setClipboard(this.dataset.link);
            GM_notification({
                title: '✅ 复制成功',
                text: '链接已复制到剪贴板',
                timeout: 2000
            });
        });

        // 通知
        GM_notification({
            title: '🎯 拦截到下载链接',
            text: type,
            timeout: 3000
        });
    }

    // 绕过激活验证
    function bypassActivation() {
        console.log('[IPA拦截] 尝试绕过激活验证...');

        // 方法1：直接触发下载
        const downloadBtn = document.querySelector('button[onclick*="install"]') ||
                          document.querySelector('a[href*="itms-services"]') ||
                          document.querySelector('.download-btn') ||
                          document.querySelector('#download');

        if (downloadBtn) {
            console.log('[IPA拦截] 找到下载按钮，尝试触发...');
            downloadBtn.click();
            GM_notification({
                title: '🔓 绕过激活',
                text: '已尝试触发下载，请查看拦截结果',
                timeout: 3000
            });
            return;
        }

        // 方法2：查找并执行install函数
        if (typeof window.install === 'function') {
            console.log('[IPA拦截] 找到install函数，执行...');
            window.install();
            return;
        }

        // 方法3：查找页面中的itms-services链接
        const links = document.querySelectorAll('a[href*="itms-services"]');
        if (links.length > 0) {
            console.log('[IPA拦截] 找到itms-services链接');
            links.forEach(link => {
                const href = link.href;
                updatePanel(href, '🔗 itms-services协议');

                // 解析manifest URL
                const match = href.match(/url=([^&]+)/);
                if (match) {
                    const manifestUrl = decodeURIComponent(match[1]);
                    updatePanel(manifestUrl, '📄 Manifest URL');

                    // 获取manifest内容
                    fetchManifest(manifestUrl);
                }
            });
            return;
        }

        GM_notification({
            title: '⚠️ 未找到下载入口',
            text: '请手动点击下载按钮',
            timeout: 3000
        });
    }

    // 获取manifest文件内容
    function fetchManifest(url) {
        console.log('[IPA拦截] 获取manifest文件:', url);

        GM_xmlhttpRequest({
            method: 'GET',
            url: url,
            onload: function(response) {
                console.log('[IPA拦截] Manifest响应:', response.responseText);

                // 解析plist文件，提取IPA URL
                const ipaMatch = response.responseText.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
                if (ipaMatch) {
                    const ipaUrl = ipaMatch[1];
                    console.log('[IPA拦截] 找到IPA下载地址:', ipaUrl);
                    updatePanel(ipaUrl, '📦 IPA下载地址');
                }
            },
            onerror: function(error) {
                console.error('[IPA拦截] 获取manifest失败:', error);
            }
        });
    }

    // Hook XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSend = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function(method, url, ...args) {
        this._url = url;
        this._method = method;

        console.log('[IPA拦截] XHR请求:', method, url);

        // 拦截关键请求
        if (url.includes('.ipa') ||
            url.includes('.plist') ||
            url.includes('manifest') ||
            url.includes('download') ||
            url.includes('install') ||
            url.includes('activate')) {

            console.log('[IPA拦截] 发现关键请求:', url);
            updatePanel(url, `🌐 ${method} 请求`);
        }

        return originalOpen.apply(this, [method, url, ...args]);
    };

    XMLHttpRequest.prototype.send = function(...args) {
        this.addEventListener('load', function() {
            if (this._url && (
                this._url.includes('.ipa') ||
                this._url.includes('.plist') ||
                this._url.includes('manifest') ||
                this._url.includes('download') ||
                this._url.includes('install') ||
                this._url.includes('activate')
            )) {
                console.log('[IPA拦截] XHR响应:', this.responseText);

                try {
                    const json = JSON.parse(this.responseText);
                    console.log('[IPA拦截] JSON响应:', json);

                    // 查找可能的下载链接
                    const findUrls = (obj, path = '') => {
                        for (let key in obj) {
                            if (typeof obj[key] === 'string') {
                                if (obj[key].includes('.ipa') ||
                                    obj[key].includes('itms-services') ||
                                    obj[key].includes('manifest')) {
                                    console.log('[IPA拦截] 在JSON中找到链接:', obj[key]);
                                    updatePanel(obj[key], `📊 JSON.${path}${key}`);
                                }
                            } else if (typeof obj[key] === 'object' && obj[key] !== null) {
                                findUrls(obj[key], `${path}${key}.`);
                            }
                        }
                    };

                    findUrls(json);
                } catch (e) {
                    // 不是JSON，尝试查找URL
                    const urlMatches = this.responseText.match(/https?:\/\/[^\s"'<>]+\.(ipa|plist)/g);
                    if (urlMatches) {
                        urlMatches.forEach(url => {
                            console.log('[IPA拦截] 在响应中找到链接:', url);
                            updatePanel(url, '📄 响应文本');
                        });
                    }
                }
            }
        });

        return originalSend.apply(this, args);
    };

    // Hook fetch API
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        const url = args[0];

        console.log('[IPA拦截] Fetch请求:', url);

        if (typeof url === 'string' && (
            url.includes('.ipa') ||
            url.includes('.plist') ||
            url.includes('manifest') ||
            url.includes('download') ||
            url.includes('install') ||
            url.includes('activate')
        )) {
            console.log('[IPA拦截] 发现关键Fetch请求:', url);
            updatePanel(url, '🌐 Fetch请求');
        }

        return originalFetch.apply(this, args).then(response => {
            // 克隆响应以便读取
            const clonedResponse = response.clone();

            clonedResponse.text().then(text => {
                if (typeof url === 'string' && (
                    url.includes('.ipa') ||
                    url.includes('.plist') ||
                    url.includes('manifest') ||
                    url.includes('download') ||
                    url.includes('install') ||
                    url.includes('activate')
                )) {
                    console.log('[IPA拦截] Fetch响应:', text);

                    // 尝试解析JSON
                    try {
                        const json = JSON.parse(text);
                        const findUrls = (obj) => {
                            for (let key in obj) {
                                if (typeof obj[key] === 'string' && (
                                    obj[key].includes('.ipa') ||
                                    obj[key].includes('itms-services') ||
                                    obj[key].includes('manifest')
                                )) {
                                    updatePanel(obj[key], `📊 Fetch JSON.${key}`);
                                }
                            }
                        };
                        findUrls(json);
                    } catch (e) {
                        // 查找URL
                        const urlMatches = text.match(/https?:\/\/[^\s"'<>]+\.(ipa|plist)/g);
                        if (urlMatches) {
                            urlMatches.forEach(url => {
                                updatePanel(url, '📄 Fetch响应');
                            });
                        }
                    }
                }
            });

            return response;
        });
    };

    // Hook window.location
    const originalLocationSetter = Object.getOwnPropertyDescriptor(window.location, 'href').set;
    Object.defineProperty(window.location, 'href', {
        set: function(value) {
            console.log('[IPA拦截] window.location.href =', value);

            if (value.includes('itms-services') ||
                value.includes('.ipa') ||
                value.includes('manifest')) {
                updatePanel(value, '🔗 window.location跳转');

                // 解析itms-services
                if (value.includes('itms-services')) {
                    const match = value.match(/url=([^&]+)/);
                    if (match) {
                        const manifestUrl = decodeURIComponent(match[1]);
                        updatePanel(manifestUrl, '📄 Manifest URL');
                        fetchManifest(manifestUrl);
                    }
                }
            }

            return originalLocationSetter.call(this, value);
        }
    });

    // 页面加载完成后创建悬浮窗并显示拦截到的数据
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            createFloatingPanel();
            displayInterceptedData();
        });
    } else {
        createFloatingPanel();
        displayInterceptedData();
    }

    // 显示拦截到的数据
    function displayInterceptedData() {
        // 显示appInstall拦截的数据
        if (window._interceptedData && window._interceptedData.length > 0) {
            window._interceptedData.forEach(item => {
                updatePanel(JSON.stringify(item.data), `📱 ${item.type} (${item.timestamp})`);
            });
        }

        // 显示找到的下载链接
        if (window._downloadLinks && window._downloadLinks.length > 0) {
            window._downloadLinks.forEach(item => {
                updatePanel(item.url, `🎯 ${item.path} (${item.timestamp})`);
            });
        }

        // 定期检查新数据
        setInterval(displayInterceptedData, 1000);
    }

    // 监听页面中的所有链接点击
    document.addEventListener('click', function(e) {
        const target = e.target.closest('a, button');
        if (!target) return;

        const href = target.href || target.getAttribute('onclick') || '';

        if (href.includes('itms-services') ||
            href.includes('.ipa') ||
            href.includes('manifest') ||
            href.includes('install') ||
            href.includes('download')) {

            console.log('[IPA拦截] 点击事件:', href);
            updatePanel(href, '🖱️ 点击链接');
        }
    }, true);

    console.log('[IPA拦截] 所有Hook已设置完成');

})();
