#!/usr/bin/env bun

import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";
import { buildApp, runCommand } from "./build-app";
import {
  readBuildNumber,
  readPackageVersion,
  syncVersionAndBumpBuildNumber,
} from "./version";

async function main(): Promise<void> {
  const args = Bun.argv.slice(2);
  const bump = args.includes("--bump");
  const noPublish = args.includes("--no-publish");

  console.log(chalk.bold.magenta("📦 开始 QxCar 生产构建与发布准备..."));

  let version: string;
  let buildNumber: string;

  if (bump) {
    const synced = syncVersionAndBumpBuildNumber();
    version = synced.version;
    buildNumber = synced.buildNumber;
    console.log(
      chalk.blue("ℹ 递增构建编号: ") + chalk.yellow(`v${version} (${buildNumber})`),
    );
  } else {
    version = readPackageVersion();
    buildNumber = readBuildNumber();
  }

  const app = await buildApp({
    configuration: "release",
    version,
    buildNumber,
    productName: "QxCar",
    bundleIdentifier: "com.qzrzz.qxcar",
    signIdentity: "-",
  });

  // 打包 zip
  const releaseDir = join(import.meta.dir, "..", "build", "Release");
  const zipPath = join(releaseDir, `QxCar-v${version}.zip`);

  console.log(chalk.bold.cyan("▶ 创建发布压缩包: ") + chalk.yellow(zipPath));
  await runCommand([
    "ditto",
    "-c",
    "-k",
    "--sequesterRsrc",
    "--keepParent",
    app.appPath,
    zipPath,
  ]);

  console.log(
    chalk.bold.green("✨ 构建与打包完成! 产物位于: \n") +
      chalk.whiteBright(`   - 应用: ${app.appPath}\n`) +
      chalk.whiteBright(`   - 压缩包: ${zipPath}`),
  );
}

main().catch((error) => {
  console.error("\n" + chalk.red("✗ 出错: ") + (error instanceof Error ? error.message : error));
  process.exit(1);
});
