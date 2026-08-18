#!/usr/bin/env bun

import {
  chmodSync,
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import chalk from "chalk";

export type BuildConfiguration = "debug" | "release";

export interface AppBuildOptions {
  configuration: BuildConfiguration;
  version: string;
  buildNumber: string;
  productName?: string;
  bundleIdentifier?: string;
  signIdentity?: string;
}

export interface AppBuildResult {
  appPath: string;
  executablePath: string;
  configuration: BuildConfiguration;
  version: string;
  buildNumber: string;
}

const ROOT_DIR = join(import.meta.dir, "..");
const TARGET_NAME = "QxCar";
const RESOURCE_BUNDLE_NAME = TARGET_NAME + "_" + TARGET_NAME + ".bundle";
const ICON_SOURCE_PNG = join(ROOT_DIR, "icons/QxCar-1.png");

export async function runCommand(command: string[], cwd = ROOT_DIR): Promise<void> {
  const child = Bun.spawn(command, {
    cwd,
    env: Bun.env,
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });
  const code = await child.exited;
  if (code !== 0) {
    throw new Error(`命令执行失败 (退出代码 ${code}): ${command.join(" ")}`);
  }
}

export async function captureCommand(command: string[], cwd = ROOT_DIR): Promise<string> {
  const child = Bun.spawn(command, {
    cwd,
    env: Bun.env,
    stdout: "pipe",
    stderr: "pipe",
  });
  const [code, stdout, stderr] = await Promise.all([
    child.exited,
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
  ]);
  if (code !== 0) {
    throw new Error(
      `命令执行失败 (退出代码 ${code}): ${command.join(" ")}\n${stderr.trim()}`,
    );
  }
  return stdout.trim();
}

/**
 * 从 PNG 图片生成标准 macOS .icns 文件
 */
async function generateAppIconIcns(sourcePng: string, outputIcnsPath: string): Promise<void> {
  const iconsetDir = join(ROOT_DIR, "build/AppIcon.iconset");
  rmSync(iconsetDir, { recursive: true, force: true });
  mkdirSync(iconsetDir, { recursive: true });

  const targets = [
    { size: 16, scale: 1, name: "icon_16x16.png" },
    { size: 16, scale: 2, name: "icon_16x16@2x.png" },
    { size: 32, scale: 1, name: "icon_32x32.png" },
    { size: 32, scale: 2, name: "icon_32x32@2x.png" },
    { size: 128, scale: 1, name: "icon_128x128.png" },
    { size: 128, scale: 2, name: "icon_128x128@2x.png" },
    { size: 256, scale: 1, name: "icon_256x256.png" },
    { size: 256, scale: 2, name: "icon_256x256@2x.png" },
    { size: 512, scale: 1, name: "icon_512x512.png" },
    { size: 512, scale: 2, name: "icon_512x512@2x.png" },
  ];

  for (const t of targets) {
    const px = t.size * t.scale;
    const dest = join(iconsetDir, t.name);
    await runCommand(["sips", "-z", String(px), String(px), sourcePng, "--out", dest]);
  }

  await runCommand(["iconutil", "-c", "icns", iconsetDir, "-o", outputIcnsPath]);
  rmSync(iconsetDir, { recursive: true, force: true });
}

function generateInfoPlist(options: {
  productName: string;
  bundleIdentifier: string;
  version: string;
  buildNumber: string;
}): string {
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh-Hans</string>
  <key>CFBundleExecutable</key>
  <string>${options.productName}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>${options.bundleIdentifier}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${options.productName}</string>
  <key>CFBundleDisplayName</key>
  <string>${options.productName}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${options.version}</string>
  <key>CFBundleVersion</key>
  <string>${options.buildNumber}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 Qzrzz. All rights reserved.</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>Asset Catalog</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>com.apple.asset-catalog</string>
        <string>public.item</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
`;
}

export async function buildApp(options: AppBuildOptions): Promise<AppBuildResult> {
  const configuration = options.configuration;
  const productName = options.productName ?? "QxCar";
  const bundleIdentifier = options.bundleIdentifier ?? "com.qzrzz.qxcar";
  const signIdentity = options.signIdentity ?? "-";

  console.log(
    chalk.bold.cyan("▶ 开始构建 Swift 目标: ") +
      chalk.yellow(TARGET_NAME) +
      chalk.gray(` [${configuration}]`),
  );

  const swiftArgs = [
    "swift",
    "build",
    "-c",
    configuration,
  ];

  await runCommand(swiftArgs);

  const swiftBinPath = await captureCommand([
    "swift",
    "build",
    "-c",
    configuration,
    "--show-bin-path",
  ]);

  const outputBaseDir = join(
    ROOT_DIR,
    "build",
    configuration === "release" ? "Release" : "Debug",
  );
  const appPath = join(outputBaseDir, `${productName}.app`);
  const contentsPath = join(appPath, "Contents");
  const macosPath = join(contentsPath, "MacOS");
  const resourcesPath = join(contentsPath, "Resources");
  const appExecutablePath = join(macosPath, productName);

  console.log(chalk.bold.cyan("▶ 组装 macOS 应用包: ") + chalk.yellow(appPath));

  rmSync(appPath, { recursive: true, force: true });
  mkdirSync(macosPath, { recursive: true });
  mkdirSync(resourcesPath, { recursive: true });

  const sourceExecutable = join(swiftBinPath, TARGET_NAME);
  if (!existsSync(sourceExecutable)) {
    throw new Error(`未找到编译生成的可执行文件: ${sourceExecutable}`);
  }

  copyFileSync(sourceExecutable, appExecutablePath);
  chmodSync(appExecutablePath, 0o755);

  // 1. 生成并嵌入 AppIcon.icns
  if (existsSync(ICON_SOURCE_PNG)) {
    console.log(chalk.bold.cyan("▶ 生成 App 图标: ") + chalk.yellow("icons/QxCar-1.png -> AppIcon.icns"));
    const targetIcnsPath = join(resourcesPath, "AppIcon.icns");
    await generateAppIconIcns(ICON_SOURCE_PNG, targetIcnsPath);
  }

  // 2. 复制资源 Bundle (如果 SPM 生成了)
  const bundlePath = join(swiftBinPath, RESOURCE_BUNDLE_NAME);
  if (existsSync(bundlePath)) {
    cpSync(bundlePath, join(resourcesPath, RESOURCE_BUNDLE_NAME), { recursive: true });
  }

  // 3. 写入 Info.plist
  const plistContent = generateInfoPlist({
    productName,
    bundleIdentifier,
    version: options.version,
    buildNumber: options.buildNumber,
  });
  writeFileSync(join(contentsPath, "Info.plist"), plistContent, "utf8");

  // 4. 代码签名
  console.log(chalk.bold.cyan("▶ 正在进行代码签名..."));
  await runCommand([
    "codesign",
    "--force",
    "--deep",
    "--sign",
    signIdentity,
    appPath,
  ]);

  console.log(
    chalk.bold.green("✔ 构建成功: ") +
      chalk.whiteBright(appPath) +
      chalk.gray(` (v${options.version} build ${options.buildNumber})`),
  );

  return {
    appPath,
    executablePath: appExecutablePath,
    configuration,
    version: options.version,
    buildNumber: options.buildNumber,
  };
}
