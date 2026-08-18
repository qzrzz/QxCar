#!/usr/bin/env bun

import chalk from "chalk";
import { buildApp, runCommand } from "./build-app";
import { readBuildNumber, readPackageVersion } from "./version";

async function main(): Promise<void> {
  console.log(chalk.bold.magenta("🚀 启动 QxCar 开发模式..."));

  const app = await buildApp({
    configuration: "debug",
    version: readPackageVersion(),
    buildNumber: readBuildNumber(),
    productName: "QxCar Dev",
    bundleIdentifier: "com.qzrzz.qxcar.dev",
    signIdentity: "-",
  });

  console.log(chalk.bold.green("✓ 启动应用: ") + chalk.cyan(app.appPath));
  await runCommand([app.executablePath]);
}

main().catch((error) => {
  console.error("\n" + chalk.red("✗ 出错: ") + (error instanceof Error ? error.message : error));
  process.exit(1);
});
