# CkOpenImage

This plugin is intended to show a picture from an URL into a Photo Viewer with zoom features.

> Based on [Photo Viewer][https://github.com/sarriaroman/photoviewer]


## How to Install

```bash
cordova plugin add de-cyberkatze-ckopenimage --save
```

### API

```js
CkOpenImage.open(<URI>, [title, options]);
```

#### Open an image

```js
CkOpenImage.open('http://my_site.com/my_image.jpg', 'Optional Title');
```

##### Usage

```
CkOpenImage.open('http://my_site.com/my_image.jpg', 'Optional Title', {share:false});
```
