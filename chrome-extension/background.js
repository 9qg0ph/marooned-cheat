// 后台脚本 - 拦截网络请求
console.log('[扩展] 后台脚本已加载');

// 存储拦截到的数据
let interceptedData = {
  shortLink: null,
  appId: null,
  token: null,
  downloadUrls: []
};

// 拦截所有网络请求
chrome.webRequest.onBeforeRequest.addListener(
  function(details) {
    console.log('[扩展] 拦截到请求:', details.url);
    
    // 拦截install API请求
    if (details.url.includes('/install') && details.url.includes('ios80.com')) {
      console.log('[扩展] 🎯 拦截到install API请求');
      
      // 提取参数
      const url = new URL(details.url);
      const appId = url.searchParams.get('appId');
      const token = url.searchParams.get('token');
      const shortLink = url.pathname.split('/')[1];
      
      interceptedData.appId = appId;
      interceptedData.token = token;
      interceptedData.shortLink = shortLink;
      
      console.log('[扩展] 提取的参数:', interceptedData);
      
      // 通知content script
      chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        if (tabs[0]) {
          chrome.tabs.sendMessage(tabs[0].id, {
            type: 'API_INTERCEPTED',
            data: interceptedData
          });
        }
      });
    }
    
    return {};
  },
  {urls: ["https://*.ios80.com/*"]},
  ["requestBody"]
);

// 拦截响应
chrome.webRequest.onCompleted.addListener(
  function(details) {
    if (details.url.includes('/install') && details.url.includes('ios80.com')) {
      console.log('[扩展] install API响应完成:', details.statusCode);
      
      // 通知content script开始绕过尝试
      chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        if (tabs[0]) {
          chrome.tabs.sendMessage(tabs[0].id, {
            type: 'START_BYPASS',
            data: interceptedData
          });
        }
      });
    }
  },
  {urls: ["https://*.ios80.com/*"]}
);

// 监听来自content script的消息
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  console.log('[扩展] 收到消息:', request);
  
  if (request.type === 'SHORTLINK_INTERCEPTED') {
    interceptedData.shortLink = request.data;
    console.log('[扩展] shortLink已更新:', interceptedData.shortLink);
    
    // 立即开始绕过尝试
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      if (tabs[0]) {
        chrome.tabs.sendMessage(tabs[0].id, {
          type: 'START_BYPASS',
          data: interceptedData
        });
      }
    });
  }
  
  if (request.type === 'DOWNLOAD_URL_FOUND') {
    interceptedData.downloadUrls.push(request.data);
    console.log('[扩展] 找到下载URL:', request.data);
    
    // 存储到本地
    chrome.storage.local.set({
      'interceptedData': interceptedData
    });
  }
  
  sendResponse({success: true});
});

console.log('[扩展] 后台脚本初始化完成');