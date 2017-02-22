# cordova-plugin-ckopenimage

Cordova plugin is intended to show a picture from an URL into a Photo Viewer with zoom features.

> Based on [Photo Viewer](https://github.com/sarriaroman/photoviewer)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/WuglyakBolgoink/CkOpenImage/master/LICENSE)
[![iOS](https://img.shields.io/badge/iOS-success-green.svg)](https://shields.io)

[![NPM](https://nodei.co/npm/cordova-plugin-ckopenimage.png?stars=true)](https://nodei.co/npm/cordova-plugin-ckopenimage/)
[![NPM](https://nodei.co/npm-dl/cordova-plugin-ckopenimage.png?months=1)](https://nodei.co/npm-dl/cordova-plugin-ckopenimage.png?months=1)

## How to Install

```bash
cordova plugin add cordova-plugin-ckopenimage --save
```

### API

```js
CkOpenImage.open(<URI>, [title]);
```

#### Open an image

```js
CkOpenImage.open('http://my_site.com/my_image.jpg', 'Optional Title');
```

##### Usage

```js
CkOpenImage.open('http://my_site.com/my_image.jpg', 'Optional Title');
```

```js
CkOpenImage.open('http://my_site.com/my_image.jpg', 'image.jpg');
```


### TODO

- add options
- add isAvailable()
