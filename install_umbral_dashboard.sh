#!/bin/bash
set -e
cd ~/GameStudio 2>/dev/null || { echo "ERROR: ~/GameStudio not found"; exit 1; }

echo ""
echo "  ██    ██ ███    ███ ██████  ██████   █████  ██"
echo "  ██    ██ ████  ████ ██   ██ ██   ██ ██   ██ ██"
echo "  ██    ██ ██ ████ ██ ██████  ██████  ███████ ██"
echo "  ██    ██ ██  ██  ██ ██   ██ ██   ██ ██   ██ ██"
echo "   ██████  ██      ██ ██████  ██   ██ ██   ██ ███████"
echo ""
echo "  Deploying Living Dashboard to GitHub Pages..."
echo ""

mkdir -p docs
echo "[1/1] Writing docs/index.html..."

cat > docs/index.html << 'ENDDASH'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UMBRAL STUDIO — AI Game Studio Command Center</title>
<meta name="description" content="UMBRAL — AI-powered solo game studio. 10 Claude agents, Godot 4, one developer. A shadow learning to dance with light.">
<meta property="og:title" content="UMBRAL STUDIO — Command Center">
<meta property="og:description" content="One developer. Ten AI agents. A game about a shadow separated from its child.">
<meta property="og:type" content="website">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=VT323&display=swap" rel="stylesheet">
<style>
:root{--bg:#002b2b;--win-bg:#d4d0c8;--title-active:linear-gradient(90deg,#0a246a 0%,#3a6ea5 100%);--title-inactive:linear-gradient(90deg,#7f7f7f 0%,#b5b5b5 100%);--t:#1a1a2e;--g:#20c20e;--a:#c8a000;--c:#00b8d4;--w:#b0bec5;--r:#d32f2f;--b:#42a5f5;--m:#ab47bc;--p:#ff6ec7;--d:#445}
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:#001a1a;min-height:100vh;overflow-x:hidden}

/* ── Boot sequence ── */
#boot-screen{position:fixed;inset:0;background:#000;z-index:9999;display:flex;flex-direction:column;justify-content:center;padding:40px;font-family:'VT323',monospace;color:var(--g);font-size:16px;line-height:1.6;transition:opacity 0.8s}
#boot-screen.hidden{opacity:0;pointer-events:none}
#boot-lines span{display:block;opacity:0;animation:bootIn 0.15s forwards}
@keyframes bootIn{to{opacity:1}}

/* ── Desktop ── */
.dk{background:var(--bg);padding:6px;font-family:'IBM Plex Mono',monospace;position:relative;min-height:100vh;display:none}
.dk.visible{display:block}
.dk::after{content:'';position:absolute;inset:0;pointer-events:none;background:repeating-linear-gradient(0deg,transparent,transparent 3px,rgba(0,0,0,0.03) 3px,rgba(0,0,0,0.03) 4px)}
.gr{display:grid;gap:5px}
.g2{grid-template-columns:1fr 1fr}
.g32{grid-template-columns:3fr 2fr}

/* ── Windows ── */
.W{border:2px outset #ddd;background:var(--win-bg);margin-bottom:5px}
.Wt{background:var(--title-active);height:20px;display:flex;align-items:center;padding:0 3px;gap:3px}
.Wt.off{background:var(--title-inactive)}
.Wn{color:#fff;font-size:10px;font-weight:500;flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.Wb{width:14px;height:12px;background:var(--win-bg);border:1px outset #ddd;display:inline-flex;align-items:center;justify-content:center;font-size:7px;color:#000;cursor:pointer;user-select:none}
.Wb:active{border-style:inset}
.Wm{background:var(--win-bg);border-bottom:1px solid #808080;display:flex;padding:1px 0}
.Wmi{padding:1px 6px;font-size:10px;color:#000;cursor:pointer;user-select:none}
.Wmi:hover{background:#0a246a;color:#fff}

/* ── Terminal body ── */
.T{background:var(--t);color:var(--g);padding:6px 8px;font-family:'VT323',monospace;font-size:13px;line-height:1.45;border:2px inset #444;overflow:hidden}
.Ts{font-size:11px}
.sep{border-bottom:1px solid #2a2a4a;margin:3px 0}
.sr{display:flex;justify-content:space-between;padding:1px 0}

/* ── Colors ── */
.cg{color:var(--g)}.ca{color:var(--a)}.cc{color:var(--c)}.cw{color:var(--w)}.cr{color:var(--r)}.cb{color:var(--b)}.cm{color:var(--m)}.cp{color:var(--p)}.cd{color:var(--d)}

/* ── Animations ── */
.bk{animation:bk 1s step-end infinite}
@keyframes bk{50%{opacity:0}}
.log-line{opacity:0;animation:fadeIn 0.3s forwards}
@keyframes fadeIn{to{opacity:1}}
.thought-bubble{background:rgba(0,229,255,0.06);border-left:2px solid var(--c);padding:2px 6px;margin:2px 0}

/* ── Agent monitor ── */
.wave{display:inline-flex;align-items:flex-end;gap:1px;height:24px;vertical-align:middle}
.wave-bar{width:2px;background:var(--g);transition:height 0.15s;border-radius:1px 1px 0 0}
.pulse-dot{display:inline-block;width:6px;height:6px;border-radius:50%;margin:0 3px;vertical-align:middle}
.pulse-on{background:var(--g);box-shadow:0 0 4px var(--g)}
.pulse-off{background:#333}
.pulse-busy{background:var(--a);box-shadow:0 0 4px var(--a)}

/* ── Taskbar ── */
.tb{display:flex;align-items:center;gap:3px;background:var(--win-bg);border-top:2px solid #fff;padding:2px 3px;height:28px;position:fixed;bottom:0;left:0;right:0;z-index:100}
.sb{background:var(--win-bg);border:2px outset #ddd;padding:1px 6px 1px 3px;font-family:'IBM Plex Mono',monospace;font-size:10px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:3px;height:22px}
.sb:active{border-style:inset}
.tux{width:14px;height:14px;background:#222;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:9px;color:#ffd700}
.ti{display:flex;gap:2px;flex:1;overflow:hidden}
.tii{background:var(--win-bg);border:1px inset #bbb;padding:1px 4px;font-size:8px;height:20px;display:flex;align-items:center;gap:2px;white-space:nowrap;color:#000;cursor:pointer}
.tii.on{border-style:inset;background:#bbb}
.tc{font-family:'VT323',monospace;font-size:12px;color:#000;border:1px inset #bbb;padding:1px 6px;background:var(--win-bg)}
.tb-stat{font-size:8px;color:#000;margin:0 2px}

/* ── Responsive ── */
@media(max-width:900px){.g2,.g32{grid-template-columns:1fr}}
@media(max-width:600px){.T{font-size:11px}.Ts{font-size:10px}.Wn{font-size:9px}}

/* ── Footer link ── */
.repo-link{display:block;text-align:center;padding:8px;margin-bottom:32px}
.repo-link a{color:var(--c);font-family:'IBM Plex Mono',monospace;font-size:11px;text-decoration:none;border:1px solid var(--d);padding:4px 12px}
.repo-link a:hover{background:rgba(0,229,255,0.1);border-color:var(--c)}
</style>
</head>
<body>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- BOOT SEQUENCE                                                         -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div id="boot-screen">
<div id="boot-lines"></div>
</div>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- DESKTOP                                                                -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="dk" id="desktop">

<!-- ROW 1: Core + Agent Monitor -->
<div class="gr g2">
<div>

<!-- SYSTEM MONITOR -->
<div class="W">
<div class="Wt"><div class="Wn">umbral@nexus:~$ — UMBRAL Core Systems</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T">
<span class="cc">UMBRAL GAME STUDIO</span> <span class="cw">v0.1.0</span> <span class="cd">// kernel 6.8.0-umbral</span>
<br><span class="cd">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<div class="sr"><span class="cd">uptime:</span><span class="cg" id="uptime">0h 0m 0s</span></div>
<div class="sr"><span class="cd">developer:</span><span class="cw">Spencer Cottrell</span></div>
<div class="sr"><span class="cd">agents:</span><span class="cg">10/10 loaded</span><span class="cd"> | </span><span class="ca">5 active</span></div>
<div class="sr"><span class="cd">engine:</span><span class="ca">Godot 4.6.1</span></div>
<div class="sr"><span class="cd">ai model:</span><span class="cm">Claude Sonnet 4 (Anthropic)</span></div>
<div class="sr"><span class="cd">lang:</span><span class="cw">GDScript + Python 3.13</span></div>
<div class="sr"><span class="cd">target:</span><span class="cg">$9.99 Steam + itch.io</span></div>
<div class="sep"></div>
<div class="sr"><span class="cw">Sprint 1</span><span class="cg">██████████████████████ 6/6 DONE</span></div>
<div class="sr"><span class="cw">Sprint 2</span><span class="ca">█████████████░░░░░░░░ 3/5 LIVE</span></div>
<div class="sr"><span class="cw">Overall </span><span class="cc">████████░░░░░░░░░░░░░ 36%</span></div>
<div class="sep"></div>
<div class="sr"><span class="cd">files:</span><span class="cg" id="stat-files">—</span><span class="cd"> | shaders:</span><span class="cm" id="stat-shaders">—</span><span class="cd"> | loc:</span><span class="cc" id="stat-loc">—</span></div>
<div class="sr"><span class="cd">commits:</span><span class="cw" id="stat-commits">—</span><span class="cd"> | branch:</span><span class="cg">main</span><span class="cd"> | last:</span><span class="ca" id="stat-last">—</span></div>
</div>
</div>

<!-- IPC BUS -->
<div class="W">
<div class="Wt"><div class="Wn">&#9733; agent_ipc — Inter-Agent Communication Bus</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="Wm"><span class="Wmi">Monitor</span><span class="Wmi">Filter</span><span class="Wmi">Agents</span><span class="Wmi">Log Level</span></div>
<div class="T Ts" id="ipc-log" style="height:175px;overflow:hidden">
<span class="cd">Listening on unix:///tmp/umbral_ipc.sock ...</span>
</div>
</div>

</div>
<div>

<!-- AGENT HTOP -->
<div class="W">
<div class="Wt"><div class="Wn">htop — Agent Neural Activity Monitor</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T Ts">
<span class="cd">PID  AGENT          STATE   CPU   MEM   NEURAL   CTX</span>
<div class="sep"></div>
<div class="sr"><span class="cd">001</span> <span class="cc">&#9733;</span> <span class="cw">creative_dir </span><span class="pulse-dot pulse-on"></span><span class="cg">ACTV</span> <span class="cd">12%</span> <span class="cd"> 84M</span> <span id="nw0" class="wave"></span> <span class="cd">42K</span></div>
<div class="sr"><span class="cd">002</span> <span class="ca">&#9998;</span> <span class="cw">narrative_des</span> <span class="pulse-dot pulse-on"></span><span class="cg">ACTV</span> <span class="cd"> 8%</span> <span class="cd"> 62M</span> <span id="nw1" class="wave"></span> <span class="cd">38K</span></div>
<div class="sr"><span class="cd">003</span> <span class="cm">&#9670;</span> <span class="cw">art_director </span><span class="pulse-dot pulse-on"></span><span class="cg">ACTV</span> <span class="cd">15%</span> <span class="cd"> 91M</span> <span id="nw2" class="wave"></span> <span class="cd">51K</span></div>
<div class="sr"><span class="cd">004</span> <span class="cb">&#9835;</span> <span class="cw">sound_design </span><span class="pulse-dot pulse-off"></span><span class="cd">IDLE</span> <span class="cd"> 1%</span> <span class="cd"> 24M</span> <span id="nw3" class="wave"></span> <span class="cd">12K</span></div>
<div class="sr"><span class="cd">005</span> <span class="cg">&#9000;</span> <span class="cw">lead_program </span><span class="pulse-dot pulse-busy"></span><span class="ca">CODE</span> <span class="cr" id="cpu5">94%</span> <span class="ca">256M</span> <span id="nw4" class="wave"></span> <span class="ca" id="ctx5">128K</span></div>
<div class="sr"><span class="cd">006</span> <span class="cw">&#9776;</span> <span class="cw">producer     </span><span class="pulse-dot pulse-on"></span><span class="cg">ACTV</span> <span class="cd"> 6%</span> <span class="cd"> 48M</span> <span id="nw5" class="wave"></span> <span class="cd">29K</span></div>
<div class="sr"><span class="cd">007</span> <span class="cm">&#10070;</span> <span class="cw">shader_artst </span><span class="pulse-dot pulse-on"></span><span class="cg">ACTV</span> <span class="cd">22%</span> <span class="cd">128M</span> <span id="nw6" class="wave"></span> <span class="cd">67K</span></div>
<div class="sr"><span class="cd">008</span> <span class="cr">&#9888;</span> <span class="cw">qa_tester    </span><span class="pulse-dot pulse-off"></span><span class="cd">STBY</span> <span class="cd"> 2%</span> <span class="cd"> 32M</span> <span id="nw7" class="wave"></span> <span class="cd">15K</span></div>
<div class="sr"><span class="cd">009</span> <span class="cc">&#9787;</span> <span class="cw">ux_research  </span><span class="pulse-dot pulse-off"></span><span class="cd">IDLE</span> <span class="cd"> 1%</span> <span class="cd"> 18M</span> <span id="nw8" class="wave"></span> <span class="cd"> 8K</span></div>
<div class="sr"><span class="cd">010</span> <span class="ca">&#9654;</span> <span class="cw">playtester   </span><span class="pulse-dot pulse-off"></span><span class="cd">WAIT</span> <span class="cd"> 0%</span> <span class="cd"> 12M</span> <span id="nw9" class="wave"></span> <span class="cd"> 4K</span></div>
<div class="sep"></div>
<span class="cd">total: </span><span class="cw" id="total-cpu">161%</span><span class="cd"> cpu | </span><span class="cw">755M</span><span class="cd"> mem | </span><span class="cc">394K ctx</span><span class="cd"> | </span><span class="cg" id="msg-rate">847 msg/s</span>
</div>
</div>

<!-- THOUGHT STREAM -->
<div class="W">
<div class="Wt"><div class="Wn">&#9998; lead_programmer — Live Cognitive Stream</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T Ts" id="thought-stream" style="height:112px;overflow:hidden">
<span class="cd">Attaching to pid 005 cognitive stream...</span>
</div>
</div>

</div>
</div>

<!-- ROW 2: Git + Sprint + Art -->
<div class="gr g32">
<div>

<!-- GIT LOG -->
<div class="W">
<div class="Wt"><div class="Wn">git log --oneline --graph — Live Repository</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T Ts" id="git-log" style="min-height:80px">
<span class="cd">Fetching from github.com/colonel1223/GameStudio ...</span>
</div>
</div>

<!-- SPRINT TRACKER -->
<div class="W">
<div class="Wt"><div class="Wn">sprint-tracker — Task Status</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="Wm"><span class="Wmi">View</span><span class="Wmi">Sprint</span><span class="Wmi">Filter</span><span class="Wmi">Help</span></div>
<div class="T Ts">
<span class="cc">── SPRINT 1: FOUNDATION ──</span> <span class="cg">[COMPLETE]</span>
<br><span class="cg"> [x]</span><span class="cd"> Project setup + Git repo</span>
<br><span class="cg"> [x]</span><span class="cd"> SignalBus autoload (38 signals)</span>
<br><span class="cg"> [x]</span><span class="cd"> Shadow player controller v1</span>
<br><span class="cg"> [x]</span><span class="cw"> Custom 2D lighting system</span>
<br><span class="cg"> [x]</span><span class="cw"> Shadow casting &#8594; Area2D platforms</span>
<br><span class="cg"> [x]</span><span class="cw"> GameManager autoload</span>
<div class="sep"></div>
<span class="ca">── SPRINT 2: VERTICAL SLICE ──</span> <span class="ca">[ACTIVE]</span>
<br><span class="cc"> [x]</span><span class="cw"> Shadow stretch ability</span> <span class="ca">[READY]</span>
<br><span class="cc"> [x]</span><span class="cw"> Level 1 greybox (White Room)</span> <span class="ca">[READY]</span>
<br><span class="cc"> [x]</span><span class="cw"> Shadow player v2 (full)</span> <span class="ca">[READY]</span>
<br><span class="cd"> [ ]</span><span class="cw"> Candle grab/move mechanic</span>
<br><span class="cd"> [ ]</span><span class="cw"> 30-sec gameplay capture</span>
<div class="sep"></div>
<span class="cd">── SPRINT 3-12: UPCOMING ──</span>
<br><span class="cd"> [ ] Light system (3 types) &#183; Player systems &#183; Levels 2-4</span>
<br><span class="cd"> [ ] Audio implementation &#183; Visual polish &#183; Launch prep</span>
<br><span class="cd"> [ ] Steam store page &#183; Marketing &#183; LAUNCH</span>
</div>
</div>

</div>
<div>

<!-- ART DIRECTOR -->
<div class="W">
<div class="Wt"><div class="Wn">&#9670; art_director — Visual Identity</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T Ts">
<span class="cc">COLOR PALETTE</span>
<br><span style="color:#FFFEF7">&#9608;&#9608;</span> <span class="cd">Washi White  #FFFEF7</span>
<br><span style="color:#555;background:#444">&#9608;&#9608;</span> <span class="cd">Sumi Black   #0A0A0A</span>
<br><span style="color:#8B4513">&#9608;&#9608;</span> <span class="cd">Burnt Umber  #8B4513</span>
<br><span style="color:#2F4F4F">&#9608;&#9608;</span> <span class="cd">Slate Gray   #2F4F4F</span>
<br><span style="color:#DC143C">&#9608;&#9608;</span> <span class="cd">Vermillion   #DC143C</span>
<div class="sep"></div>
<span class="cm">SHADER PIPELINE</span>
<br><span class="cg">[&#9632;]</span><span class="cw"> shadow_dissolve</span><span class="cd"> 165ln</span>
<br><span class="cg">[&#9632;]</span><span class="cw"> ink_stain</span><span class="cd">        55ln</span>
<br><span class="cg">[&#9632;]</span><span class="cw"> light_bloom</span><span class="cd">      60ln</span>
<br><span class="cd">[&#9633;]</span><span class="cd"> paper_grain     S3</span>
<div class="sep"></div>
<span class="cc">ART STYLE</span><span class="cd">: sumi-e ink painting</span>
<br><span class="cd">ref: Gris &#215; Limbo &#215; Sessh&#363;</span>
</div>
</div>

<!-- FILE LISTING -->
<div class="W">
<div class="Wt"><div class="Wn">ls -la ~/GameStudio/game/ — Live Files</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T Ts" id="file-list">
<span class="cd">reading directory...</span>
</div>
</div>

</div>
</div>

<!-- ROW 3: Mission -->
<div class="W">
<div class="Wt"><div class="Wn">cat /etc/umbral/MISSION.md</div><div class="Wb">_</div><div class="Wb">&#9633;</div><div class="Wb">X</div></div>
<div class="T" style="text-align:center;padding:10px">
<span class="cc">THE MISSION</span>
<br><span class="cw">The gaming industry optimized for extraction.</span>
<br><span class="cw">UMBRAL is built on the belief that one person with AI tools</span>
<br><span class="cw">can ship a game with more artistic integrity than a 200-person</span>
<br><span class="cw">team spending $50M on loot box psychology.</span>
<br><span class="ca">No microtransactions. No battle pass. No artificial grind.</span>
<br><span class="cg">Just a shadow, light, and a story worth telling.</span>
<div class="sep"></div>
<span class="cd">Built by Spencer Cottrell &#183; San Jose, CA &#183; 2026</span>
</div>
</div>

<div class="repo-link">
<a href="https://github.com/colonel1223/GameStudio" target="_blank" rel="noopener">&#9632; View Full Source on GitHub &#8594; colonel1223/GameStudio</a>
</div>

<!-- spacer for taskbar -->
<div style="height:32px"></div>

</div><!-- /desktop -->

<!-- TASKBAR -->
<div class="tb" id="taskbar" style="display:none">
<div class="sb"><span class="tux">&#9824;</span> UMBRAL</div>
<div class="ti">
  <div class="tii on">&#9632; nexus</div>
  <div class="tii on">&#9632; agent_ipc</div>
  <div class="tii">&#9632; htop</div>
  <div class="tii">&#9632; thought</div>
  <div class="tii">&#9632; git log</div>
  <div class="tii">&#9632; sprint</div>
</div>
<div style="display:flex;align-items:center;gap:4px">
<span class="tb-stat" id="tb-msgs">&#9650; 0 msg/s</span>
<span class="tb-stat" id="tb-cpu">CPU 161%</span>
<div class="tc" id="clk">00:00</div>
</div>
</div>

<script>
/* ═══════════════════════════════════════════════════════════════════════════ */
/* BOOT SEQUENCE                                                             */
/* ═══════════════════════════════════════════════════════════════════════════ */
var bootLines=[
  'BIOS Shadow Systems Inc. v4.20',
  'Detecting CPU... Claude Sonnet 4 Neural Core [OK]',
  'Memory test: 755M agent workspace [PASS]',
  'Loading kernel 6.8.0-umbral ...',
  'Mounting /proc/agents ... 10 daemons found',
  'Starting agent_ipc.service ... [OK]',
  'Starting creative_director.service ... [OK]',
  'Starting narrative_designer.service ... [OK]',
  'Starting art_director.service ... [OK]',
  'Starting lead_programmer.service ... [OK]',
  'Starting producer.service ... [OK]',
  'Starting shader_artist.service ... [OK]',
  'Binding neural IPC socket: /tmp/umbral_ipc.sock',
  'Initializing X11 framebuffer ... 1920x1080@60Hz',
  'Loading GTK theme: LinuxClassic2001',
  'Connecting to github.com/colonel1223/GameStudio ...',
  '',
  'UMBRAL STUDIO v0.1.0 — ALL SYSTEMS NOMINAL',
  'Welcome, Spencer.',
];
var bootEl=document.getElementById('boot-lines');
var bootScreen=document.getElementById('boot-screen');
var desktop=document.getElementById('desktop');
var taskbar=document.getElementById('taskbar');
var bi=0;
function bootNext(){
  if(bi>=bootLines.length){
    setTimeout(function(){
      bootScreen.classList.add('hidden');
      desktop.classList.add('visible');
      taskbar.style.display='flex';
      setTimeout(function(){bootScreen.style.display='none';},800);
      startSystems();
    },600);
    return;
  }
  var s=document.createElement('span');
  s.textContent=bootLines[bi];
  s.style.animationDelay='0s';
  bootEl.appendChild(s);
  bi++;
  setTimeout(bootNext, bi<3?200:bi<10?120:80);
}
setTimeout(bootNext,400);

/* ═══════════════════════════════════════════════════════════════════════════ */
/* LIVE SYSTEMS                                                              */
/* ═══════════════════════════════════════════════════════════════════════════ */
function startSystems(){
  startClock();
  startUptime();
  startWaves();
  startIPC();
  startThoughts();
  startCPUJitter();
  fetchGitHub();
}

/* Clock */
function startClock(){
  var c=document.getElementById('clk');
  function t(){c.textContent=new Date().toLocaleTimeString('en-US',{hour:'2-digit',minute:'2-digit',hour12:false});}
  t();setInterval(t,15000);
}

/* Uptime */
function startUptime(){
  var el=document.getElementById('uptime');
  var s=0;
  setInterval(function(){
    s++;
    var h=Math.floor(s/3600),m=Math.floor((s%3600)/60),sec=s%60;
    el.textContent=h+'h '+m+'m '+sec+'s';
  },1000);
}

/* Neural waveforms */
function startWaves(){
  var ids=['nw0','nw1','nw2','nw3','nw4','nw5','nw6','nw7','nw8','nw9'];
  var act=[0.6,0.5,0.7,0.1,1.0,0.4,0.7,0.15,0.08,0.03];
  ids.forEach(function(id){
    var el=document.getElementById(id);if(!el)return;
    for(var i=0;i<8;i++){var b=document.createElement('span');b.className='wave-bar';b.style.height='2px';b.style.width='2px';el.appendChild(b);}
  });
  setInterval(function(){
    ids.forEach(function(id,idx){
      var el=document.getElementById(id);if(!el)return;
      el.querySelectorAll('.wave-bar').forEach(function(b){
        var h=Math.max(2,Math.random()*24*act[idx]);
        b.style.height=h+'px';
        b.style.background=act[idx]>0.8?'#c8a000':act[idx]>0.3?'#20c20e':'#333';
      });
    });
  },200);
}

/* CPU jitter */
function startCPUJitter(){
  setInterval(function(){
    var c=document.getElementById('cpu5');
    var v=88+Math.floor(Math.random()*11);
    if(c)c.textContent=v+'%';
    var t=document.getElementById('total-cpu');
    if(t)t.textContent=(v+67)+'%';
    var tb=document.getElementById('tb-cpu');
    if(tb)tb.textContent='CPU '+(v+67)+'%';
    var ctx=document.getElementById('ctx5');
    if(ctx)ctx.textContent=Math.floor(125+Math.random()*8)+'K';
    var mr=document.getElementById('msg-rate');
    var rate=800+Math.floor(Math.random()*120);
    if(mr)mr.textContent=rate+' msg/s';
    var tbm=document.getElementById('tb-msgs');
    if(tbm)tbm.textContent='\u25B2 '+rate+' msg/s';
  },2000);
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* INTER-AGENT COMMUNICATION BUS                                             */
/* ═══════════════════════════════════════════════════════════════════════════ */
var ipcMsgs=[
  {f:'lead_program',t:'art_director',m:'shadow_dissolve.gdshader uniforms validated \u2014 brush_noise_scale clamped at 20.0',c:'#20c20e'},
  {f:'art_director',t:'lead_program',m:'adding paper_influence uniform for Act 3 hospital scenes \u2014 cooler dissolve feel',c:'#ab47bc'},
  {f:'creative_dir',t:'narrative_des',m:'memory fragment in White Room needs to feel accidental \u2014 child touches shadow by mistake',c:'#00b8d4'},
  {f:'narrative_des',t:'creative_dir',m:'rewriting: shadow reaches toward candle, child\'s memory bleeds through the floor stain',c:'#c8a000'},
  {f:'producer',t:'lead_program',m:'Sprint 2 deadline: shadow_abilities.gd MUST have stretch collision working before Friday',c:'#b0bec5'},
  {f:'lead_program',t:'producer',m:'stretch bridge collision tested \u2014 StaticBody2D with dynamic RectangleShape2D, 60fps stable',c:'#20c20e'},
  {f:'shader_artst',t:'art_director',m:'light_bloom watercolor rings at 4 concentric layers \u2014 matches 80px falloff spec exactly',c:'#ab47bc'},
  {f:'art_director',t:'shader_artst',m:'add breathing modulation to ring opacity \u2014 15% variance at 0.8s period per design doc',c:'#00b8d4'},
  {f:'qa_tester',t:'lead_program',m:'EDGE CASE: dissolve_amount exceeds 1.0 when two lights overlap \u2014 needs clamp',c:'#d32f2f'},
  {f:'lead_program',t:'qa_tester',m:'patched in _check_light_vulnerability \u2014 accumulates then clamps. adding triple-light test',c:'#20c20e'},
  {f:'creative_dir',t:'producer',m:'Level 1 gap width at 5 tiles feels right \u2014 forces stretch discovery without punishing',c:'#00b8d4'},
  {f:'ux_research',t:'creative_dir',m:'coyote_time 0.12s benchmarked \u2014 Celeste uses 0.1s, Hollow Knight 0.15s. we\'re in range',c:'#00b8d4'},
  {f:'narrative_des',t:'art_director',m:'Act 1 ending: shadow curls into spiral (pause gesture) seeing child\'s bed \u2014 hold 3sec',c:'#c8a000'},
  {f:'sound_design',t:'narrative_des',m:'queuing shakuhachi sample for memory trigger \u2014 single note, D minor, 2sec decay',c:'#42a5f5'},
  {f:'producer',t:'creative_dir',m:'Sprint 2 at 60% \u2014 stretch + greybox + player v2 done. remaining: candle grab + capture',c:'#b0bec5'},
  {f:'lead_program',t:'shader_artst',m:'ink_stain leaving traces \u2014 gray #F5F5F5 on paper, bleed radius 0.3, looks beautiful',c:'#20c20e'},
  {f:'playtester',t:'producer',m:'awaiting playable build for gap-crossing test \u2014 need shadow_abilities hooked to input map',c:'#c8a000'},
  {f:'art_director',t:'creative_dir',m:'golden ratio placement for candle: position (192, 384) \u2014 1.618:1 from room edges',c:'#ab47bc'},
  {f:'lead_program',t:'qa_tester',m:'vulnerability_map at 32px grid \u2014 perf tested with 4 lights: 0.8ms per frame update',c:'#20c20e'},
  {f:'creative_dir',t:'narrative_des',m:'the shadow should never speak. emotion through posture and edge quality only \u2014 per spec',c:'#00b8d4'},
];
var ipcIdx=0;
function startIPC(){
  var el=document.getElementById('ipc-log');
  function add(){
    var m=ipcMsgs[ipcIdx%ipcMsgs.length];
    var ts=new Date().toLocaleTimeString('en-US',{hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:false});
    var ln=document.createElement('div');
    ln.className='log-line';
    ln.innerHTML='<span class="cd">'+ts+'</span> <span style="color:'+m.c+'">'+m.f+'</span><span class="cd"> \u2192 </span><span class="cw">'+m.t+'</span><span class="cd">: </span><span style="color:#8a9a8a">'+m.m+'</span>';
    el.appendChild(ln);
    if(el.children.length>13)el.removeChild(el.children[1]);
    el.scrollTop=el.scrollHeight;
    ipcIdx++;
  }
  setTimeout(add,800);
  setTimeout(add,1800);
  setInterval(add,3200);
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* THOUGHT STREAM                                                            */
/* ═══════════════════════════════════════════════════════════════════════════ */
var thoughts=[
  {y:'think',x:'analyzing stretch collision \u2014 StaticBody2D at midpoint, RectangleShape2D resized to current_length...'},
  {y:'decide',x:'width_curve with 4 points: (0,1.0) (0.3,0.9) (0.7,0.6) (1.0,0.15) \u2014 thick base, thin tip'},
  {y:'code',x:'_stretch_visual.width_curve.add_point(Vector2(0.0, 1.0)) // full width at shadow origin'},
  {y:'think',x:'integrity drain 0.15/sec = 6.6 seconds max stretch \u2014 enough to cross 5-tile gap with margin...'},
  {y:'decide',x:'adding wobble: sin(t * PI * 3.0) * 2.0 * t \u2014 stable at base, organic at tip'},
  {y:'code',x:'var target_length := minf(origin.distance_to(mouse_pos), max_stretch_distance)'},
  {y:'think',x:'level_01 gap at 5 tiles = 160px, max_stretch 280px \u2014 player has room to aim imprecisely...'},
  {y:'decide',x:'variable jump: velocity.y *= 0.5 on release \u2014 short tap = small hop, hold = full arc'},
  {y:'code',x:'_dissolve_amount = minf(_dissolve_amount + dissolve_speed * delta, 1.0) // clamp overflow'},
  {y:'think',x:'memory fragment emits shadow_ability_gained("stretch") through SignalBus \u2014 clean decoupling...'},
  {y:'decide',x:'fragment pulse rate 2.0s matches art doc ink-drop cycle \u2014 subtle player draw'},
  {y:'code',x:'img.fill(Color(0.04, 0.04, 0.04, 0.92)) // pure sumi-e ink black'},
  {y:'think',x:'light check interval 0.1s balances responsiveness vs perf cost at scale...'},
  {y:'decide',x:'capsule collision: radius 10, height 28 \u2014 slim shadow silhouette, offset -14 for grounding'},
  {y:'code',x:'velocity.y = jump_force; _jump_buffer_timer = 0.0; _coyote_timer = 0.0;'},
  {y:'think',x:'if _current_light_intensity > 0.5: dissolve. if > 0.15: slow dissolve. else: safe reform...'},
];
var thIdx=0;
function startThoughts(){
  var el=document.getElementById('thought-stream');
  function add(){
    var t=thoughts[thIdx%thoughts.length];
    var pre,col;
    if(t.y==='think'){pre='REASONING ';col='#556';}
    else if(t.y==='decide'){pre='DECISION  ';col='#00b8d4';}
    else{pre='CODEGEN   ';col='#20c20e';}
    var ln=document.createElement('div');
    ln.className='log-line'+(t.y==='think'?' thought-bubble':'');
    ln.innerHTML='<span style="color:'+col+'">'+pre+'</span><span class="cw">'+t.x+'</span>';
    el.appendChild(ln);
    if(el.children.length>8)el.removeChild(el.children[1]);
    el.scrollTop=el.scrollHeight;
    thIdx++;
  }
  setTimeout(add,600);
  setTimeout(add,2200);
  setInterval(add,4500);
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* LIVE GITHUB API                                                           */
/* ═══════════════════════════════════════════════════════════════════════════ */
function fetchGitHub(){
  var api='https://api.github.com/repos/colonel1223/GameStudio';

  fetch(api+'/commits?per_page=15')
    .then(function(r){return r.json()})
    .then(function(commits){
      var el=document.getElementById('git-log');
      el.innerHTML='';
      var sc=document.getElementById('stat-commits');
      if(sc)sc.textContent=commits.length+'';
      var sl=document.getElementById('stat-last');
      if(sl&&commits[0]){
        var d=new Date(commits[0].commit.author.date);
        sl.textContent=d.toLocaleDateString('en-US',{month:'short',day:'numeric'});
      }
      commits.forEach(function(c,i){
        var hash=c.sha.substring(0,7);
        var msg=c.commit.message.split('\n')[0];
        if(msg.length>62)msg=msg.substring(0,60)+'..';
        var isHead=i===0?' <span class="cc">(HEAD)</span>':'';
        var mc=i===0?'cw':'cd';
        var ln=document.createElement('div');
        ln.innerHTML='<span class="cr">*</span> <span class="ca">'+hash+'</span> <span class="'+mc+'">'+msg+'</span>'+isHead;
        el.appendChild(ln);
      });
      var footer=document.createElement('div');
      footer.innerHTML='<br><span class="cd">'+commits.length+' commits | </span><span class="cc">colonel1223/GameStudio</span>';
      el.appendChild(footer);
    })
    .catch(function(){
      document.getElementById('git-log').innerHTML='<span class="cr">error fetching commits \u2014 check network</span>';
    });

  fetch(api+'/git/trees/main?recursive=1')
    .then(function(r){return r.json()})
    .then(function(tree){
      if(!tree.tree)return;
      var gd=0,shader=0,loc=0;
      var files=[];
      tree.tree.forEach(function(f){
        if(f.type!=='blob')return;
        if(f.path.endsWith('.gd')){gd++;files.push({p:f.path,s:f.size,t:'gd'});}
        if(f.path.endsWith('.gdshader')){shader++;files.push({p:f.path,s:f.size,t:'sh'});}
        if(f.path.endsWith('.py'))files.push({p:f.path,s:f.size,t:'py'});
      });
      var sf=document.getElementById('stat-files');if(sf)sf.textContent=gd+' gdscript';
      var ss=document.getElementById('stat-shaders');if(ss)ss.textContent=shader+' glsl';
      var sll=document.getElementById('stat-loc');
      var totalBytes=0;files.forEach(function(f){totalBytes+=f.size||0;});
      var estLoc=Math.round(totalBytes/35);
      if(sll)sll.textContent=estLoc.toLocaleString()+' LOC';

      var fl=document.getElementById('file-list');
      fl.innerHTML='<span class="cd">drwxr-xr-x spencer staff '+files.length+' items</span>';
      var gameFiles=files.filter(function(f){return f.p.startsWith('game/');});
      gameFiles.sort(function(a,b){return a.p.localeCompare(b.p);});
      gameFiles.forEach(function(f){
        var name=f.p.replace('game/','');
        var icon=f.t==='sh'?'<span class="cm">\u25C6</span>':'<span class="ca">\u25A0</span>';
        var sz=f.s>1024?Math.round(f.s/1024)+'K':f.s+'B';
        var d=document.createElement('div');
        d.innerHTML=icon+' <span class="cg">'+name+'</span><span class="cd" style="float:right">'+sz+'</span>';
        fl.appendChild(d);
      });
    })
    .catch(function(){});
}
</script>
</body>
</html>

ENDDASH


echo ""
echo "  ✓ Dashboard deployed to docs/index.html"
echo "  Size: $(wc -c < docs/index.html | tr -d ' ') bytes"
echo ""
echo "  Committing and pushing..."
git add docs/index.html
git commit -m "feat: deploy living agent command center dashboard

- Linux 2000s X11 window manager aesthetic
- Live Inter-Agent Communication Bus (20 agent messages cycling)
- Lead Programmer cognitive thought stream (REASONING/DECISION/CODEGEN)
- Neural activity waveforms per agent (animated)
- Real-time GitHub API integration (commits, files, LOC)
- Boot sequence animation
- CPU jitter simulation, live uptime counter
- Sprint tracker, art director palette, shader pipeline
- Taskbar with live clock and system stats"
git push origin main

echo ""
echo "  ✓ LIVE at https://colonel1223.net/GameStudio/"
echo "  ✓ (or https://colonel1223.github.io/GameStudio/)"
echo ""
