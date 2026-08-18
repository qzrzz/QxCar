#!/usr/bin/env bun

import { rmSync } from "node:fs";
import { join } from "node:path";
import chalk from "chalk";

const rootDir = join(import.meta.dir, "..");
rmSync(join(rootDir, "build"), { recursive: true, force: true });
rmSync(join(rootDir, ".build"), { recursive: true, force: true });
console.log(chalk.green("✓ ") + chalk.cyan("已清理 build/ 与 .build/ 缓存目录"));
