import { IPageMeta, ISection, IQPageConfig } from "qpage";

export const config: IQPageConfig = {
  defaultLang: "zh-Hans",
};

export const page: IPageMeta = {
  productTitle: "QxCar",
  productTitleCN: "Car 资源提取",
  tagline: "提取 macOS 应用 Assets.car 中的图片资源和 .icon 源文件",
  taglineShort: "提取 Assets.car 资源和图标",
  platforms: ["macos"],
  icon: "../icons/QxCar.png",
  iconFull: "../icons/QxCar-full-256.png",
  metaDesc: "UI 设计师必备，提取 macOS 应用 Assets.car 中的图片资源和 .icon ",
  githubRepo: "https://github.com/qzrzz/QxCar",
  onlineUrl: "https://qzrzz.com/QxCar",
  downloadBase: "https://download.qzrzz.com/QxCar",
  mainScreenshotImage: "./assets/s1.png",
};

export const sections: ISection[] = [
  {
    id: "why",
    title: "为什么需要这个",
    isNav: true,
    description:
      "macOS 系统图标有很多精妙设计，作为 UI 设计师为 macOS 设计图标参考官方图标是非常好的途径，使用 QxCar 可以把提取应用的图标，并且生成带图层和特效参数的 .icon 源文件，使用苹果官方 Icon Composer 打开编辑",
    cards: [
      {
        image: "./assets/s2.png",
        style: "center",

        imageDesc: "Assets.car 是 Apple 平台开发工具将 Assets.xcassets 等资源编译、优化后生成的二进制资源包，供系统在运行时高效加载图片、颜色和 App 图标等资源。",
      },
    ],
  },

  {
    id: "what",
    title: "提取图片资源和 .icon 源文件",
    isNav: true,
    description: "拖拽应用程序到 QxCar 即可提取资源，会提取全部图片资源，并生成 .icon 源文件",
    cards: [{ image: "./assets/s3.png", style: "center" }],
  },
];
