// Popup界面脚本
console.log('[扩展] Popup脚本已加载');

let interceptCount = 0;
let results = [];

// DOM元素
const elements = {
  extensionStatus: document.getElementById('extensionStatus'),
  currentPage: document.getElementById('currentPage'),
  interceptCount: document.getElementById('interceptCount'),
  startIntercept: document.getElementById('startIntercept'),
  clearResults: document.getElementById('clearResults'),
  exportResults: document.getElementById('exportResults'),
  openOptions: document.getElementById('openOptions'),
  resultsPanel: document.getElementById('resultsPanel'),
  resultsList: document.getElementById('resultsList'),
  loadingPanel: document.getElementById('loadingPanel')
};

// 初始化
document.addEventListener('DOMContentLoaded', function() {
  console.log('[扩展] Popup DOM加载完成');
  
  // 获取当前标签页信息
  getCurrentTabInfo();
  
  // 加载存储的数据
  loadStoredData();
  
  // 绑定事件
  bindEvents();
  
  // 更新状态
  updateStatus();
});

// 获取当前标签页信息
function getCurrentTabInfo() {
  chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
    if (tabs[0]) {
      const tab = tabs[0];
      const url = new URL(tab.url);
      
      elements.currentPage.textContent = url.hostname;
      
      // 检查是否是目标网站
      if (url.hostname.includes('ios80.com')) {
        elements.extensionStatus.textContent = '已激活';
        elements.extensionStatus.className = 'status-value success';
      } else {
        elements.extensionStatus.textContent = '待激活';
        elements.extensionStatus.className = 'status-value warning';
      }
    }
  });
}

// 加载存储的数据
function loadStoredData() {
  chrome.storage.local.get(['interceptedData', 'interceptCount'], function(data) {
    if (data.interceptedData) {
      results = data.interceptedData.downloadUrls || [];
      updateResultsDisplay();
    }
    
    if (data.interceptCount) {
      interceptCount = data.interceptCount;
      elements.interceptCount.textContent = interceptCount;
    }
  });
}

// 绑定事件
function bindEvents() {
  // 开始拦截按钮
  elements.startIntercept.addEventListener('click', function() {
    startInterception();
  });
  
  // 清除结果按钮
  elements.clearResults.addEventListener('click', function() {
    clearResults();
  });
  
  // 导出结果按钮
  elements.exportResults.addEventListener('click', function() {
    exportResults();
  });
  
  // 设置选项按钮
  elements.openOptions.addEventListener('click', function() {
    chrome.tabs.create({url: 'chrome://extensions/?id=' + chrome.runtime.id});
  });
}

// 开始拦截
function startInterception() {
  console.log('[扩展] 开始拦截...');
  
  elements.loadingPanel.classList.remove('hidden');
  elements.startIntercept.disabled = true;
  elements.startIntercept.textContent = '拦截中...';
  
  // 向当前标签页发送开始拦截消息
  chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, {
        type: 'START_MANUAL_INTERCEPT'
      }, function(response) {
        console.log('[扩展] 拦截消息已发送:', response);
      });
    }
  });
  
  // 3秒后恢复按钮状态
  setTimeout(() => {
    elements.loadingPanel.classList.add('hidden');
    elements.startIntercept.disabled = false;
    elements.startIntercept.textContent = '🚀 开始拦截';
  }, 3000);
}

// 清除结果
function clearResults() {
  results = [];
  interceptCount = 0;
  
  elements.interceptCount.textContent = '0';
  elements.resultsPanel.classList.add('hidden');
  elements.resultsList.innerHTML = '';
  
  // 清除存储
  chrome.storage.local.clear();
  
  showMessage('结果已清除', 'success');
}

// 导出结果
function exportResults() {
  if (results.length === 0) {
    showMessage('没有可导出的结果', 'warning');
    return;
  }
  
  const exportData = {
    timestamp: new Date().toISOString(),
    interceptCount: interceptCount,
    results: results
  };
  
  const dataStr = JSON.stringify(exportData, null, 2);
  const blob = new Blob([dataStr], {type: 'application/json'});
  const url = URL.createObjectURL(blob);
  
  // 创建下载链接
  const a = document.createElement('a');
  a.href = url;
  a.download = `ipa_intercept_results_${Date.now()}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  
  URL.revokeObjectURL(url);
  
  showMessage('结果已导出', 'success');
}

// 更新结果显示
function updateResultsDisplay() {
  if (results.length === 0) {
    elements.resultsPanel.classList.add('hidden');
    return;
  }
  
  elements.resultsPanel.classList.remove('hidden');
  elements.resultsList.innerHTML = '';
  
  results.forEach((result, index) => {
    const item = document.createElement('div');
    item.className = 'result-item';
    
    item.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px;">
        <span style="font-weight: bold;">${result.source || '未知来源'}</span>
        <button onclick="copyToClipboard('${result.url}')" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 2px 6px; border-radius: 3px; cursor: pointer; font-size: 10px;">复制</button>
      </div>
      <div style="word-break: break-all; opacity: 0.9;">${result.url}</div>
    `;
    
    elements.resultsList.appendChild(item);
  });
}

// 复制到剪贴板
window.copyToClipboard = function(text) {
  navigator.clipboard.writeText(text).then(() => {
    showMessage('已复制到剪贴板', 'success');
  }).catch(() => {
    showMessage('复制失败', 'error');
  });
};

// 显示消息
function showMessage(message, type = 'info') {
  const messageEl = document.createElement('div');
  messageEl.style.cssText = `
    position: fixed;
    top: 10px;
    left: 50%;
    transform: translateX(-50%);
    background: ${type === 'success' ? '#4CAF50' : type === 'error' ? '#f44336' : type === 'warning' ? '#FF9800' : '#2196F3'};
    color: white;
    padding: 8px 16px;
    border-radius: 6px;
    font-size: 12px;
    z-index: 1000;
  `;
  
  messageEl.textContent = message;
  document.body.appendChild(messageEl);
  
  setTimeout(() => {
    messageEl.remove();
  }, 2000);
}

// 更新状态
function updateStatus() {
  // 检查扩展权限
  chrome.permissions.contains({
    permissions: ['webRequest', 'storage', 'tabs', 'scripting'],
    origins: ['https://*.ios80.com/*']
  }, function(result) {
    if (result) {
      console.log('[扩展] 权限检查通过');
      elements.extensionStatus.textContent = '已激活';
      elements.extensionStatus.className = 'status-value success';
    } else {
      elements.extensionStatus.textContent = '权限不足';
      elements.extensionStatus.className = 'status-value error';
    }
  });
}

// 监听来自background的消息
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  console.log('[扩展] Popup收到消息:', request);
  
  if (request.type === 'INTERCEPT_SUCCESS') {
    interceptCount++;
    elements.interceptCount.textContent = interceptCount;
    
    if (request.data) {
      results.push(request.data);
      updateResultsDisplay();
    }
    
    // 保存到存储
    chrome.storage.local.set({
      interceptCount: interceptCount,
      interceptedData: { downloadUrls: results }
    });
    
    showMessage('拦截成功!', 'success');
  }
  
  sendResponse({success: true});
});

console.log('[扩展] Popup脚本初始化完成');