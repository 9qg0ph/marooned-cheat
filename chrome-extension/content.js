// Content Script - 在页面中执行
console.log('[扩展] Content Script已加载');

// 立即注入脚本到页面
const script = document.createElement('script');
script.src = chrome.runtime.getURL('inject.js');
script.onload = function() {
  this.remove();
};
(document.head || document.documentElement).appendChild(script);

// 监听来自inject.js的消息
window.addEventListener('message', function(event) {
  if (event.source !== window) return;
  
  if (event.data.type === 'APPINSTALL_CALLED') {
    console.log('[扩展] 收到appInstall调用:', event.data.shortLink);
    
    // 通知background script
    chrome.runtime.sendMessage({
      type: 'SHORTLINK_INTERCEPTED',
      data: event.data.shortLink
    });
    
    // 显示成功提示
    showNotification('🎯 扩展成功拦截！\nshortLink: ' + event.data.shortLink, 'success');
  }
});

// 监听来自background script的消息
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  console.log('[扩展] Content收到消息:', request);
  
  if (request.type === 'START_BYPASS') {
    console.log('[扩展] 开始绕过尝试...');
    startBypassAttempts(request.data);
  }
  
  sendResponse({success: true});
});

// 开始绕过尝试
function startBypassAttempts(data) {
  console.log('[扩展] 🚀 开始绕过尝试:', data);
  
  showNotification('开始绕过尝试...', 'info');
  
  const { shortLink, appId, token } = data;
  
  if (!shortLink) {
    console.error('[扩展] shortLink为空');
    return;
  }
  
  // 创建结果显示面板
  createResultPanel();
  addResult('开始绕过尝试...', '🚀 状态');
  addResult(`shortLink: ${shortLink}`, '📱 拦截数据');
  
  // 策略1: 直接尝试manifest URLs
  tryManifestUrls(shortLink, appId, token);
  
  // 策略2: 尝试IPA直接下载
  setTimeout(() => tryDirectIpaUrls(shortLink, appId, token), 1000);
  
  // 策略3: 尝试API端点
  setTimeout(() => tryApiEndpoints(shortLink, appId, token), 2000);
}

// 策略1: 尝试manifest URLs
function tryManifestUrls(shortLink, appId, token) {
  console.log('[扩展] 策略1: 尝试manifest URLs...');
  addResult('尝试manifest文件...', '🔍 策略1');
  
  const manifestUrls = [
    `https://app.ios80.com/${shortLink}/manifest.plist`,
    `https://cdn.ios80.com/${shortLink}/manifest.plist`,
    `https://files.ios80.com/${shortLink}/manifest.plist`,
    `https://storage.ios80.com/manifest/${shortLink}.plist`,
    `https://app.ios80.com/api/manifest/${shortLink}.plist`,
    `https://app.ios80.com/download/${shortLink}/manifest.plist`
  ];
  
  manifestUrls.forEach((url, index) => {
    setTimeout(() => {
      console.log(`[扩展] 尝试manifest ${index + 1}:`, url);
      
      fetch(url, {
        method: 'GET',
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
          'Accept': 'application/x-plist, */*'
        }
      })
      .then(response => {
        console.log(`[扩展] Manifest ${index + 1} 响应:`, response.status);
        
        if (response.status === 200) {
          return response.text();
        }
        throw new Error(`Status: ${response.status}`);
      })
      .then(text => {
        if (text.includes('<plist')) {
          console.log('[扩展] ✅ 找到有效manifest!');
          addResult(url, `✅ Manifest ${index + 1}`);
          
          // 解析IPA URL
          const ipaMatch = text.match(/<string>(https?:\/\/[^<]+\.ipa)<\/string>/);
          if (ipaMatch) {
            const ipaUrl = ipaMatch[1];
            console.log('[扩展] 🎉 找到IPA地址:', ipaUrl);
            
            foundIpaUrl(ipaUrl, 'Manifest解析');
          }
        }
      })
      .catch(error => {
        console.log(`[扩展] Manifest ${index + 1} 失败:`, error.message);
      });
    }, index * 200);
  });
}

// 策略2: 尝试IPA直接下载
function tryDirectIpaUrls(shortLink, appId, token) {
  console.log('[扩展] 策略2: 尝试IPA直接下载...');
  addResult('尝试IPA直接下载...', '🔍 策略2');
  
  const ipaUrls = [
    `https://app.ios80.com/download/${shortLink}.ipa`,
    `https://cdn.ios80.com/apps/${shortLink}.ipa`,
    `https://files.ios80.com/${shortLink}.ipa`,
    `https://storage.ios80.com/${shortLink}.ipa`,
    `https://app.ios80.com/ipa/${shortLink}.ipa`,
    `https://app.ios80.com/files/${appId}.ipa`
  ];
  
  ipaUrls.forEach((url, index) => {
    setTimeout(() => {
      console.log(`[扩展] 尝试IPA ${index + 1}:`, url);
      
      fetch(url, { method: 'HEAD' })
      .then(response => {
        console.log(`[扩展] IPA ${index + 1} 响应:`, response.status);
        
        if (response.status === 200) {
          const contentType = response.headers.get('content-type') || '';
          if (contentType.includes('application/octet-stream') || 
              contentType.includes('application/zip') ||
              contentType.includes('application/x-ios-app')) {
            
            console.log('[扩展] 🎉 找到IPA文件!');
            foundIpaUrl(url, `IPA直接下载 ${index + 1}`);
          }
        }
      })
      .catch(error => {
        console.log(`[扩展] IPA ${index + 1} 失败:`, error.message);
      });
    }, index * 300);
  });
}

// 策略3: 尝试API端点
function tryApiEndpoints(shortLink, appId, token) {
  console.log('[扩展] 策略3: 尝试API端点...');
  addResult('尝试API端点...', '🔍 策略3');
  
  const apiUrls = [
    `https://app.ios80.com/api/download/${shortLink}`,
    `https://api.ios80.com/download/${shortLink}`,
    `https://app.ios80.com/api/v1/install/${shortLink}`,
    `https://app.ios80.com/internal/download/${shortLink}`,
    `https://app.ios80.com/admin/install/${shortLink}`
  ];
  
  apiUrls.forEach((url, index) => {
    setTimeout(() => {
      console.log(`[扩展] 尝试API ${index + 1}:`, url);
      
      fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-App-Id': appId,
          'X-Short-Link': shortLink
        }
      })
      .then(response => {
        if (response.status === 200) {
          return response.text();
        }
        throw new Error(`Status: ${response.status}`);
      })
      .then(text => {
        console.log(`[扩展] API ${index + 1} 响应:`, text.substring(0, 200));
        addResult(text.substring(0, 300), `API ${index + 1} 响应`);
        
        // 查找URL
        findUrlsInText(text, `API ${index + 1}`);
      })
      .catch(error => {
        console.log(`[扩展] API ${index + 1} 失败:`, error.message);
      });
    }, index * 400);
  });
}

// 找到IPA URL时的处理
function foundIpaUrl(url, source) {
  console.log('[扩展] 🎉🎉🎉 找到IPA URL:', url);
  
  addResult(url, `🎉 ${source}`);
  
  // 复制到剪贴板
  navigator.clipboard.writeText(url).then(() => {
    showNotification('🎉 IPA地址已复制到剪贴板！', 'success');
  }).catch(() => {
    showNotification('请手动复制IPA地址', 'warning');
  });
  
  // 通知background script
  chrome.runtime.sendMessage({
    type: 'DOWNLOAD_URL_FOUND',
    data: { url, source }
  });
  
  // 验证URL有效性
  fetch(url, { method: 'HEAD' })
  .then(response => {
    const contentLength = response.headers.get('content-length');
    if (contentLength) {
      const sizeMB = (parseInt(contentLength) / 1024 / 1024).toFixed(2);
      addResult(`文件大小: ${sizeMB} MB`, '✅ URL验证');
    }
  })
  .catch(() => {
    addResult('URL验证失败', '❌ URL验证');
  });
}

// 在文本中查找URL
function findUrlsInText(text, source) {
  const patterns = [
    /https?:\/\/[^\s"'<>]+\.ipa/g,
    /https?:\/\/[^\s"'<>]+\.plist/g,
    /itms-services:\/\/[^\s"'<>]+/g
  ];
  
  patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      matches.forEach(url => {
        console.log(`[扩展] 在${source}中找到URL:`, url);
        
        if (url.includes('.ipa')) {
          foundIpaUrl(url, source);
        } else {
          addResult(url, `🎯 ${source}`);
        }
      });
    }
  });
}

// 创建结果显示面板
function createResultPanel() {
  if (document.getElementById('extension-result-panel')) return;
  
  const panel = document.createElement('div');
  panel.id = 'extension-result-panel';
  panel.style.cssText = `
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
  
  panel.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
      <h3 style="margin: 0; font-size: 18px;">🔧 Chrome扩展拦截器</h3>
      <button onclick="this.parentElement.parentElement.remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 5px 10px; border-radius: 5px; cursor: pointer;">✕</button>
    </div>
    <div id="extension-result-content"></div>
  `;
  
  document.body.appendChild(panel);
}

// 添加结果
function addResult(content, type) {
  const resultContent = document.getElementById('extension-result-content');
  if (!resultContent) return;
  
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
      <button onclick="navigator.clipboard.writeText('${content.replace(/'/g, "\\'")}').then(() => alert('已复制'))" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 4px 10px; border-radius: 5px; cursor: pointer; font-size: 11px;">📋 复制</button>
    </div>
    <div style="font-size: 13px; font-family: monospace; max-height: 150px; overflow-y: auto; white-space: pre-wrap;">${content}</div>
  `;
  
  resultContent.insertBefore(item, resultContent.firstChild);
}

// 显示通知
function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: ${type === 'success' ? '#4CAF50' : type === 'warning' ? '#FF9800' : '#2196F3'};
    color: white;
    padding: 15px 25px;
    border-radius: 8px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.3);
    z-index: 1000000;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 14px;
    white-space: pre-line;
  `;
  
  notification.textContent = message;
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.remove();
  }, 5000);
}

console.log('[扩展] Content Script初始化完成');