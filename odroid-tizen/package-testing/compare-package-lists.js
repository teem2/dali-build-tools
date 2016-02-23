var fs = require("fs");

// Pattern for extracing RPM package name from full package name, e.g.
// 'xmlsec1-openssl' for full name xmlsec1-openssl-1.2.19-8.8.armv7l
var patt = /[a-zA-Z0-9\-]*/;
// The above pattern will catch the first digit of the version number
// following the package name. This pattern is used to detect such package
// names.
var pattVersionEnd = /\-[0-9]*$/;

var versionInfo1 = {
  snapshot: 'tv_20151204.2',
  filename: 'tv_20151204.2_tv-package-list.txt',
  packages: []
};

var versionInfo2 = {
  snapshot: 'tv_20160219.2',
  filename: 'tv_20160219.2_tv-package-list.txt',
  packages: []
};

var fullPackageList = [];  // All package names across versions


function unique(arr) {
  var u = {}, a = [];
  for(var i = 0, l = arr.length; i < l; ++i){
    if(!u.hasOwnProperty(arr[i])) {
      a.push(arr[i]);
      u[arr[i]] = 1;
    }
  }
  return a;
}

function loadFile(filename) {
  var packages = [];
  var content = null;
  try {
    content = fs.readFileSync(filename).toString().split("\n");
  } catch(e) {
    console.error('Could not open file ' + filename);
    content = [];
  }
  for (var i=0; i<content.length; i++) {
    var package = content[i];
    var packageName = package.match(patt)[0];
    var shortName = packageName;
    if (packageName) {
      var endFixPos = shortName.search(pattVersionEnd);
      if (endFixPos > 0) {
        shortName = shortName.substr(0, endFixPos);
      }
      packages[packages.length] = {
        shortName: shortName,
        name: package,
        version: package.substring(shortName.length+1, package.length).replace('.armv7l', '')
      };
      // Store in global package list
      fullPackageList.push(shortName);
    }
  }
  fullPackageList = unique(fullPackageList);
  return packages;
}

function packageExists(v, shortName) {
  for (var i=0; i< v.packages.length; i++) {
    if (v.packages[i].shortName === shortName) {
      return true;
    }
  }
  return false;
}

function getVersionForPackage(v, shortName) {
  for (var i=0; i< v.packages.length; i++) {
    if (v.packages[i].shortName === shortName) {
      return v.packages[i].version;
    }
  }
  return ' (missing) ';
}

function compareVersions(v1, v2) {
  var filename = 'package-comparision-' + v1.snapshot + "_" + v2.snapshot + ".txt";
  var fileContent = "Package name," + v1.snapshot + "," + v2.snapshot + "\n";
  for (var i=0; i<fullPackageList.length; i++) {
    var shortName = fullPackageList[i];
    // console.log("Checking package: " + shortName);
    var msg = shortName + ",";
    msg += getVersionForPackage(v1, shortName) + ",";
    msg += getVersionForPackage(v2, shortName) + "\n";
    fileContent += msg;
  }
  fs.writeFileSync(filename, fileContent, "UTF-8",{'flags': 'w+'});
}

versionInfo1.packages = loadFile(versionInfo1.filename);
versionInfo2.packages = loadFile(versionInfo2.filename);

compareVersions(versionInfo1, versionInfo2);

// console.log(versionInfo2.packages);
// console.log(fullPackageList);