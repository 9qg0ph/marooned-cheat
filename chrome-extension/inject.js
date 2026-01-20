// 注入脚本 - 在页面JavaScript执行前运行
console.log('[扩展] Inject Script已加载');

// 保存原始的appInstall对象
let originalAppInstall = null;

// 创建我们的appInstall接口
const customAppInstall = {
  postMessage: function(shortLink) {
    console.log('[扩展] 🎯 appInstall.postMessage被调用!', shortLink);
    
    // 通知content script
    window.postMessage({
      type: 'APPINSTALL_CALLED',
      shortLink: shortLink
    }, '*');
    
    // 显示拦截成功提示
    showInjectNotification('🎯 扩展成功拦截appInstall调用!\nshortLink: ' + shortLink);
    
    // 立即开始绕过尝试
    setTimeout(() => {
      window.postMessage({
        type: 'START_IMMEDIATE_BYPASS',
        shortLink: shortLink,
        pageInfo: extractPageInfo()
      }, '*');
    }, 100);
    
    // 阻止原始调用，避免弹出激活码界面
    console.log('[扩展] 已阻止原始appInstall调用');
    
    return false; // 阻止默认行为
  }
};

// 创建appPreviewResource接口
const customAppPreviewResource = {
  postMessage: function(url) {
    console.log('[扩展] appPreviewResource.postMessage被调用:', url);
    
    // 允许预览功能正常工作
    if (originalAppInstall && originalAppInstall.previewResource) {
      return originalAppInstall.previewResource.postMessage(url);
    }
    
    return true;
  }
};

// 立即定义appInstall，防止页面脚本定义
Object.defineProperty(window, 'appInstall', {
  value: customAppInstall,
  writable: false,
  configurable: false
});

Object.defineProperty(window, 'appPreviewResource', {
  value: customAppPreviewResource,
  writable: false,
  configurable: false
});

console.log('[扩展] ✅ appInstall接口已劫持');

// 监听页面加载完成
document.addEventListener('DOMContentLoaded', function() {
  console.log('[扩展] DOM加载完成，开始页面分析...');
  
  // 分析页面，提取关键信息
  analyzePage();
  
  // 监听点击事件
  document.addEventListener('click', function(event) {
    const target = event.target;
    
    // 检查是否是下载按钮
    if (target.tagName === 'BUTTON' || target.tagName === 'A') {
      const text = target.textContent || target.innerText || '';
      
      if (text.includes('下载') || text.includes('安装') || text.includes('install')) {
        console.log('[扩展] 检测到下载按钮点击:', text);
        
        // 提取页面信息
        const pageInfo = extractPageInfo();
        console.log('[扩展] 页面信息:', pageInfo);
        
        // 通知content script
        window.postMessage({
          type: 'DOWNLOAD_BUTTON_CLICKED',
          pageInfo: pageInfo
        }, '*');
      }
    }
  });
});

// 分析页面
function analyzePage() {
  const pageInfo = extractPageInfo();
  console.log('[扩展] 页面分析结果:', pageInfo);
  
  // 查找所有可能的下载相关元素
  const downloadElements = document.querySelectorAll('button, a, [onclick*="install"], [onclick*="下载"]');
  console.log('[扩展] 找到下载相关元素:', downloadElements.length);
  
  downloadElements.forEach((element, index) => {
    console.log(`[扩展] 下载元素 ${index + 1}:`, {
      tagName: element.tagName,
      text: element.textContent?.trim(),
      onclick: element.getAttribute('onclick'),
      href: element.getAttribute('href')
    });
  });
}

// 提取页面信息
function extractPageInfo() {
  const info = {
    url: window.location.href,
    shortLink: null,
    appId: null,
    token: null,
    appName: null,
    osName: null,
    iconId: null  // 新增：从图标URL提取ID
  };
  
  // 从URL提取参数
  const urlParams = new URLSearchParams(window.location.search);
  info.appId = urlParams.get('appId');
  info.token = urlParams.get('token');
  
  // 从URL路径提取shortLink
  const pathParts = window.location.pathname.split('/');
  if (pathParts.length > 1) {
    info.shortLink = pathParts[1];
  }
  
  // 从页面元素提取信息
  try {
    // 应用名称
    const appNameElements = document.querySelectorAll('#iOS_appName, #Android_appName, [class*="appName"]');
    if (appNameElements.length > 0) {
      info.appName = appNameElements[0].textContent?.trim();
    }
    
    // 操作系统
    const osElements = document.querySelectorAll('#container_iOS, #container_Android');
    osElements.forEach(el => {
      if (el.style.display !== 'none') {
        info.osName = el.id.replace('container_', '');
      }
    });
    
    // 从图标URL提取ID
    const iconElements = document.querySelectorAll('img[src*="static.ios80.com/icon/"]');
    iconElements.forEach(img => {
      const iconUrl = img.src;
      const iconMatch = iconUrl.match(/\/icon\/(\d+)_/);
      if (iconMatch) {
        info.iconId = iconMatch[1];
        console.log('[扩展] 🎯 从图标URL提取到ID:', info.iconId);
      }
    });
    
    // 从JavaScript变量提取
    if (window.shortLink) info.shortLink = window.shortLink;
    if (window.osName) info.osName = window.osName;
    
  } catch (error) {
    console.log('[扩展] 提取页面信息时出错:', error);
  }
  
  return info;
}

// 显示注入脚本的通知
function showInjectNotification(message) {
  const notification = document.createElement('div');
  notification.style.cssText = `
    position: fixed;
    top: 50px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #FF6B6B, #4ECDC4);
    color: white;
    padding: 15px 25px;
    border-radius: 10px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.3);
    z-index: 1000001;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    font-size: 14px;
    font-weight: 500;
    white-space: pre-line;
    animation: slideInDown 0.5s ease-out;
  `;
  
  // 添加动画
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideInDown {
      from {
        opacity: 0;
        transform: translateX(-50%) translateY(-20px);
      }
      to {
        opacity: 1;
        transform: translateX(-50%) translateY(0);
      }
    }
  `;
  document.head.appendChild(style);
  
  notification.textContent = message;
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.style.animation = 'slideInDown 0.5s ease-out reverse';
    setTimeout(() => notification.remove(), 500);
  }, 4000);
}

// Hook原始的install函数
const originalInstall = window.install;
window.install = function() {
  console.log('[扩展] 🎯 原始install函数被调用!');
  
  const pageInfo = extractPageInfo();
  showInjectNotification('🎯 拦截到install调用!\n' + JSON.stringify(pageInfo, null, 2));
  
  // 通知content script
  window.postMessage({
    type: 'INSTALL_FUNCTION_CALLED',
    pageInfo: pageInfo
  }, '*');
  
  // 阻止原始调用
  console.log('[扩展] 已阻止原始install调用');
  return false;
};

// Hook可能的其他函数
const functionsToHook = ['iOSAppInstall', 'install_warn', 'advertisementLink'];

functionsToHook.forEach(funcName => {
  const originalFunc = window[funcName];
  if (typeof originalFunc === 'function') {
    window[funcName] = function(...args) {
      console.log(`[扩展] 🎯 ${funcName}函数被调用!`, args);
      
      showInjectNotification(`🎯 拦截到${funcName}调用!`);
      
      // 通知content script
      window.postMessage({
        type: 'FUNCTION_CALLED',
        functionName: funcName,
        arguments: args,
        pageInfo: extractPageInfo()
      }, '*');
      
      // 对于关键函数，阻止执行
      if (funcName === 'iOSAppInstall' || funcName === 'install_warn') {
        console.log(`[扩展] 已阻止${funcName}调用`);
        return false;
      }
      
      // 其他函数允许执行
      return originalFunc.apply(this, args);
    };
  }
});

console.log('[扩展] ✅ Inject Script初始化完成');