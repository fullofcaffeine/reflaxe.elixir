#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const REG_PATH = path.join('src','reflaxe','elixir','ast','transformers','registry','ElixirASTPassRegistry.hx');
const GROUP_DIR = path.join('src','reflaxe','elixir','ast','transformers','registry','groups');
const OUT = path.join('docs','05-architecture','TRANSFORM_PASS_REGISTRY_ORDER.md');

function read(p) { return fs.readFileSync(p, 'utf8'); }

function extractNamesFromGroup(groupFile){
  const txt = read(groupFile);
  const names = [];
  const re = /name\s*:\s*"([^"]+)"\s*,[\s\S]*?enabled\s*:\s*(true|false)/g;
  let m;
  while((m = re.exec(txt))){
    if (m[2] === 'true') names.push(m[1]);
  }
  return names;
}

function emit() {
  const reg = read(REG_PATH);
  const lines = reg.split(/\r?\n/);
  const order = [];

  for (let i=0;i<lines.length;i++){
    const line = lines[i];
    // Handle group concat
    let gmatch = line.match(/groups\.([A-Za-z0-9_]+)\.build\(\)/);
    if (gmatch){
      const gfile = path.join(GROUP_DIR, gmatch[1] + '.hx');
      if (fs.existsSync(gfile)){
        const names = extractNamesFromGroup(gfile);
        order.push(...names);
      }
      continue;
    }
    // Handle direct pass entries around this line (tiny window)
    if (line.includes('name:')){
      // look ahead a small window for enabled flag
      const nameMatch = line.match(/name\s*:\s*"([^"]+)"/);
      if (nameMatch){
        let enabled = false;
        for (let j=i;j<Math.min(i+6, lines.length); j++){
          if (/enabled\s*:\s*true/.test(lines[j])){ enabled = true; break; }
          if (/enabled\s*:\s*false/.test(lines[j])){ enabled = false; break; }
        }
        if (enabled) order.push(nameMatch[1]);
      }
    }
  }

  // Write doc
  const ts = new Date().toISOString();
  let out = '# Transform Pass Registry Order\n\n';
  out += `Generated: ${ts}\n\n`;
  order.forEach((n, idx) => { out += `${idx+1}. ${n}\n`; });

  const outDir = path.dirname(OUT);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(OUT, out);
  console.log(`[registry-doc] Wrote ${OUT} with ${order.length} passes.`);
}

emit();

