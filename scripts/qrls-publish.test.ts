import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "bun:test";
import {
  collectSparkleAttachments,
  r2PublicUrl,
  readSparkleSignatures,
} from "./qrls-publish";

const sampleAppcast = `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <item>
      <title>1.0.0</title>
      <enclosure url="https://download.qzrzz.com/QxCar/QxCar-1.0.0.zip" sparkle:version="2" sparkle:shortVersionString="1.0.0" length="10" type="application/octet-stream" sparkle:edSignature="zip-sig" />
      <sparkle:deltas>
        <enclosure url="https://download.qzrzz.com/QxCar/QxCar2-1.delta" sparkle:version="2" sparkle:shortVersionString="1.0.0" length="4" type="application/octet-stream" sparkle:deltaFrom="1" sparkle:edSignature="delta-sig" />
      </sparkle:deltas>
    </item>
  </channel>
</rss>
`;

test("r2PublicUrl 使用稳定公开前缀", () => {
  expect(r2PublicUrl("appcast.xml")).toBe(
    "https://download.qzrzz.com/QxCar/appcast.xml",
  );
});

test("从 generate_appcast 产物读取当前 build 的 ZIP 与 delta 签名", () => {
  const dir = mkdtempSync(join(tmpdir(), "qxcar-qrls-"));
  const appcastPath = join(dir, "appcast.xml");
  writeFileSync(appcastPath, sampleAppcast);
  const signatures = readSparkleSignatures(appcastPath, "2");
  expect(signatures.zipSignature).toBe("zip-sig");
  expect(signatures.deltas).toEqual([
    {
      name: "QxCar2-1.delta",
      edSignature: "delta-sig",
      deltaFromVersion: "1",
    },
  ]);
});

test("collectSparkleAttachments 把签名挂到 ZIP 和 delta 上", () => {
  const dir = mkdtempSync(join(tmpdir(), "qxcar-qrls-"));
  const zipPath = join(dir, "QxCar-1.0.0.zip");
  const notesPath = join(dir, "QxCar-1.0.0.md");
  const deltaPath = join(dir, "QxCar2-1.delta");
  const appcastPath = join(dir, "appcast.xml");
  writeFileSync(zipPath, "zip");
  writeFileSync(notesPath, "notes");
  writeFileSync(deltaPath, "delta");
  writeFileSync(appcastPath, sampleAppcast);

  const files = collectSparkleAttachments(
    {
      dmgPath: join(dir, "missing.dmg"),
      zipPath,
      notesPath,
      appcastPath,
      deltaPaths: [deltaPath],
    },
    "2",
  );

  expect(files).toHaveLength(3);
  expect(files[0]).toMatchObject({
    name: "QxCar-1.0.0.zip",
    edSignature: "zip-sig",
  });
  expect(files[2]).toMatchObject({
    name: "QxCar2-1.delta",
    edSignature: "delta-sig",
    deltaFromVersion: "1",
  });
});
