const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('networkTester', {
    testWebsite: url => ipcRenderer.invoke('website:test', url)
});
