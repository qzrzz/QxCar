import { IPageMeta, ISection, IQPageConfig } from "qpage";

export const config: IQPageConfig = {
  defaultLang: "zh-Hans",
};

import UrlIcon from "../icons/QxCar.png";
import UrlIconFull from "../icons/QxCar-full-256.png";

export const page: IPageMeta = {
  productTitle: "QxCar",
  productTitleCN: "macOS 应用图标提取",
  tagline: "提取 macOS 应用 Assets.car 中的图片资源和 .icon 源文件",
  taglineShort: "提取 macOS 应用的资源和图标源文件",
  platforms: ["macos"],
  icon: UrlIcon,
  iconFull: UrlIconFull,
  metaDesc: "UI 设计师必备，提取 macOS 应用 Assets.car 中的图片资源和 .icon 源文件",
  githubRepo: "https://github.com/qzrzz/QxCar",
  onlineUrl: "https://qzrzz.com/QxCar",
  downloadBase: "https://download.qzrzz.com/QxCar",
  mainScreenshotImage: "./assets/s1.png",
};

export const sections: ISection[] = [
  {
    id: "why",
    title: "为什么需要这个",

    description:
      "macOS 系统图标包含许多精妙的设计细节。对于 UI 设计师来说，研究和参考这些官方图标，是学习 macOS 图标设计最直接的方式之一。QxCar 可以从应用中提取系统图标，并将其还原为包含完整图层结构与特效参数的 .icon 源文件。你可以直接使用 Apple 官方的 Icon Composer 打开、查看和编辑，深入了解每一个图层与效果是如何构成的。",
    cards: [
      {
        image: "./assets/s2.png",
        style: "center",
        imageDesc:
          "Assets.car 是 Apple 平台开发工具将 Assets.xcassets 等资源编译、优化后生成的二进制资源包，供系统在运行时高效加载图片、颜色和 App 图标等资源。",
      },
    ],
  },

  {
    id: "what",
    title: "提取图片资源和 .icon 源文件",

    description: "拖拽应用程序到 QxCar 即可提取资源，会提取全部图片资源，并生成 .icon 源文件",
    cards: [{ image: "./assets/s3.png", style: "center" }],
  },
];
