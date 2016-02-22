var request = require('sync-request');
var fs = require('fs');
var Download = require('download');

var releaseTag = 'tizen-tv_20160212.2'
// var releaseTag = 'tizen-tv_20160220.1'
var baseUrl = 'https://download.tizen.org/snapshots/tizen/tv/'
var downloadUrl = baseUrl + releaseTag + '/repos/arm-wayland/packages/armv7l';
var packageList = [];
var html;
var filesDownloaded = 0;
var totalFiles = 0;

function downloadPackageHtml(url) {
  var res = request('GET', url, {
    'headers': {
      'user-agent': 'example-user-agent'
    }
  });
  return res.getBody().toString();
}

function downloadFile(fileUrl, targetFolder) {
  console.log("Starting download: " + fileUrl);
  new Download({mode: '644'})
    .get(fileUrl)
    .dest(targetFolder)
    .run(function(err, files) {
      if (!err) {
        filesDownloaded++;
        console.log('Downloaded file #' + filesDownloaded + ' of ' + totalFiles + ': ' + files[0].path);
      } else {
        console.log(err);
        console.log('Error downloading file ' + files[0].path);
      }
    });

}
html = downloadPackageHtml(downloadUrl);

var patt = /<a href="(.*?)"/g;
while(match=patt.exec(html)){
  var fileName = match[1];
  if (fileName.endsWith('.rpm')) {
    packageList.push(fileName);
    totalFiles++;
  }
}

for (var i=0; i<packageList.length; i++) {
  downloadFile(downloadUrl + '/' + packageList[i], './' + releaseTag + '/');
}

console.log(filesDownloaded + ' files of ' + totalFiles + ' downloaded!');
