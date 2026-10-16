// 从遍黑体（Plangothic）里抽出超重元素简体名所需的字形，生成体积很小的字体子集。
//
// 用法：
//   node tool/subset_rare_cjk_font.mjs <opentype.js> <PlangothicP1.ttf> <PlangothicP2.ttf> <输出.ttf>
//
// 说明：
// - opentype.js 是单文件依赖，可从 https://cdn.jsdelivr.net/npm/opentype.js@1.3.4/dist/opentype.min.js 获取。
// - 遍黑体基于思源黑体、按中国大陆字形补充 CJK 扩展区，SIL OFL 1.1 授权，允许子集化与再分发。
//   按 OFL 的保留名称条款，本脚本生成的子集不使用「Plangothic / 遍黑」名称。
// - 这些字形（如 𬬻 U+2CB3B、鿫 U+9FEB）在系统字体中普遍缺失，必须随应用打包才能正常显示。
import fs from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

const [, , opentypePath, ...rest] = process.argv;
if (!opentypePath || rest.length < 3) {
  console.error(
    '用法：node tool/subset_rare_cjk_font.mjs <opentype.js> <P1.ttf> <P2.ttf> <输出.ttf>',
  );
  process.exit(2);
}

const outputPath = rest.pop();
const sourcePaths = rest;

// 104–118 号元素简体中文名用到的全部字符。
const codePoints = [
  0x2cb3b, // 104 Rf 𬬻
  0x2cb4a, // 105 Db 𬭊
  0x2cb73, // 106 Sg 𬭳
  0x2cb5b, // 107 Bh 𬭛
  0x2cb76, // 108 Hs 𬭶
  0x9fcf, // 109 Mt 鿏
  0x2b7fc, // 110 Ds 𫟼
  0x2cb2d, // 111 Rg 𬬭
  0x9fd4, // 112 Cn 鿔
  0x9fed, // 113 Nh 鿭
  0x2b4e7, // 114 Fl 𫓧
  0x9546, // 115 Mc 镆
  0x2b7f7, // 116 Lv 𫟷
  0x9fec, // 117 Ts 鿬
  0x9feb, // 118 Og 鿫
];

const opentype = require(opentypePath);
const sources = sourcePaths.map((path) => {
  const buffer = fs.readFileSync(path);
  return { path, font: opentype.parse(buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength)) };
});

const primary = sources[0].font;
const glyphs = [primary.glyphs.get(0)]; // .notdef 必须有
const missing = [];
const usedFrom = new Map();

for (const codePoint of codePoints) {
  const char = String.fromCodePoint(codePoint);
  let picked = null;
  for (const { path, font } of sources) {
    const candidate = font.charToGlyph(char);
    if (candidate && candidate.index !== 0) {
      picked = candidate;
      usedFrom.set(path, (usedFrom.get(path) ?? 0) + 1);
      break;
    }
  }
  if (!picked) {
    missing.push(codePoint);
    continue;
  }
  glyphs.push(
    new opentype.Glyph({
      name: picked.name || `uni${codePoint.toString(16).toUpperCase()}`,
      unicode: codePoint,
      advanceWidth: picked.advanceWidth,
      path: picked.path,
    }),
  );
}

if (missing.length > 0) {
  console.error(
    '以下字符在源字体中缺失：' +
      missing.map((cp) => `U+${cp.toString(16).toUpperCase()}`).join(', '),
  );
  process.exit(1);
}

const subset = new opentype.Font({
  familyName: 'RareCJKSubset',
  styleName: 'Regular',
  unitsPerEm: primary.unitsPerEm,
  ascender: primary.ascender,
  descender: primary.descender,
  glyphs,
});

fs.writeFileSync(outputPath, Buffer.from(subset.toArrayBuffer()));
console.log(
  `已生成 ${outputPath}：${glyphs.length - 1} 个字形，` +
    `${fs.statSync(outputPath).size} 字节`,
);
for (const [path, count] of usedFrom) {
  console.log(`  来自 ${path}：${count} 个字形`);
}
