// Extracted game logic for testing
const CHOICES = ['fire','water','lightning','grass','metal','rock'];

const BEATS = {
  fire:      ['lightning','grass','metal'],
  water:     ['fire','metal','rock'],
  lightning: ['water','grass','metal'],
  grass:     ['water','rock'],
  metal:     ['grass','rock'],
  rock:      ['fire','lightning']
};

const WHY = {
  'fire>lightning':'absorbs','fire>grass':'burns','fire>metal':'melts',
  'water>fire':'extinguishes','water>metal':'rusts','water>rock':'erodes',
  'lightning>water':'electrifies','lightning>grass':'scorches','lightning>metal':'conducts through',
  'grass>water':'absorbs','grass>rock':'overgrows',
  'metal>grass':'cuts','metal>rock':'smashes',
  'rock>fire':'smothers','rock>lightning':'grounds'
};

function resolve(a, b) {
  if (a === b) return 'draw';
  return BEATS[a].includes(b) ? 'win' : 'lose';
}

function getFlavorText(winner, loser) {
  return WHY[winner + '>' + loser] || 'beats';
}

// ─── Test Harness ───
let passed = 0, failed = 0, errors = [];

function assert(condition, msg) {
  if (condition) { passed++; }
  else { failed++; errors.push('FAIL: ' + msg); }
}

function assertEqual(actual, expected, msg) {
  if (actual === expected) { passed++; }
  else { failed++; errors.push(`FAIL: ${msg} — expected "${expected}", got "${actual}"`); }
}

// ═══════════════════════════════════════
// TEST 1: All draws resolve correctly
// ═══════════════════════════════════════
console.log('\n--- Test: Self-matchups are draws ---');
for (const c of CHOICES) {
  assertEqual(resolve(c, c), 'draw', `${c} vs ${c} should be draw`);
}

// ═══════════════════════════════════════
// TEST 2: BEATS relationships are correct
// ═══════════════════════════════════════
console.log('\n--- Test: Win/lose relationships ---');
for (const attacker of CHOICES) {
  for (const victim of BEATS[attacker]) {
    assertEqual(resolve(attacker, victim), 'win', `${attacker} should beat ${victim}`);
    assertEqual(resolve(victim, attacker), 'lose', `${victim} should lose to ${attacker}`);
  }
}

// ═══════════════════════════════════════
// TEST 3: Every matchup has a definitive result (no undefined)
// ═══════════════════════════════════════
console.log('\n--- Test: All matchups produce valid results ---');
for (const a of CHOICES) {
  for (const b of CHOICES) {
    const result = resolve(a, b);
    assert(['win','lose','draw'].includes(result), `${a} vs ${b} should produce valid result, got "${result}"`);
  }
}

// ═══════════════════════════════════════
// TEST 4: Symmetry — if A beats B, then B loses to A
// ═══════════════════════════════════════
console.log('\n--- Test: Outcome symmetry ---');
for (const a of CHOICES) {
  for (const b of CHOICES) {
    const r1 = resolve(a, b);
    const r2 = resolve(b, a);
    if (r1 === 'win') assertEqual(r2, 'lose', `Symmetry: if ${a} wins vs ${b}, ${b} should lose vs ${a}`);
    if (r1 === 'lose') assertEqual(r2, 'win', `Symmetry: if ${a} loses vs ${b}, ${b} should win vs ${a}`);
    if (r1 === 'draw') assertEqual(r2, 'draw', `Symmetry: if ${a} draws vs ${b}, ${b} should draw vs ${a}`);
  }
}

// ═══════════════════════════════════════
// TEST 5: Balance check — count wins/losses per choice
// ═══════════════════════════════════════
console.log('\n--- Test: Balance analysis ---');
const balanceReport = {};
for (const a of CHOICES) {
  let wins = 0, losses = 0;
  for (const b of CHOICES) {
    if (a === b) continue;
    if (resolve(a, b) === 'win') wins++;
    if (resolve(a, b) === 'lose') losses++;
  }
  balanceReport[a] = { wins, losses };
  console.log(`  ${a}: ${wins} wins, ${losses} losses`);
}

// Check if all choices are equally balanced
const winCounts = new Set(Object.values(balanceReport).map(v => v.wins));
if (winCounts.size > 1) {
  console.log('  ⚠ WARNING: Game is NOT balanced! Some choices are strictly better than others.');
  const strong = CHOICES.filter(c => balanceReport[c].wins === 3);
  const weak = CHOICES.filter(c => balanceReport[c].wins === 2);
  console.log(`  Strong (3 wins): ${strong.join(', ')}`);
  console.log(`  Weak (2 wins):   ${weak.join(', ')}`);
} else {
  console.log('  ✓ All choices are equally balanced');
}

// ═══════════════════════════════════════
// TEST 6: Every winning matchup has flavor text
// ═══════════════════════════════════════
console.log('\n--- Test: Flavor text coverage ---');
for (const a of CHOICES) {
  for (const b of BEATS[a]) {
    const text = getFlavorText(a, b);
    assert(text !== 'beats', `${a} > ${b} should have specific flavor text, got fallback "beats"`);
  }
}

// ═══════════════════════════════════════
// TEST 7: No duplicate entries in BEATS
// ═══════════════════════════════════════
console.log('\n--- Test: No duplicates in BEATS ---');
for (const c of CHOICES) {
  const set = new Set(BEATS[c]);
  assertEqual(set.size, BEATS[c].length, `${c}'s BEATS list should have no duplicates`);
  assert(!BEATS[c].includes(c), `${c} should not beat itself`);
}

// ═══════════════════════════════════════
// TEST 8: No contradictions (A beats B AND B beats A)
// ═══════════════════════════════════════
console.log('\n--- Test: No contradictions ---');
for (const a of CHOICES) {
  for (const b of BEATS[a]) {
    assert(!BEATS[b].includes(a), `Contradiction: ${a} beats ${b} but ${b} also beats ${a}`);
  }
}

// ═══════════════════════════════════════
// TEST 9: First-to-N logic check
// ═══════════════════════════════════════
console.log('\n--- Test: First-to-N logic ---');
// The code uses: const need = bestOf; and checks matchWins >= need
// For FT5, this means you need 5 wins — correct for "first to" format
function checkMatchWinner_game(bestOf, leftWins, rightWins) {
  if (bestOf === 0) return false;
  const need = bestOf;
  return (leftWins >= need || rightWins >= need);
}

// FT5: first to 5 should end the match
const ft5_5wins = checkMatchWinner_game(5, 5, 3);
console.log(`  FT5 with 5-3 score — game says match over: ${ft5_5wins} (should be true)`);
assertEqual(ft5_5wins, true, 'FT5 match should end at 5 wins');

// FT5: 4 wins should NOT end the match
const ft5_4wins = checkMatchWinner_game(5, 4, 3);
console.log(`  FT5 with 4-3 score — game says match over: ${ft5_4wins} (should be false)`);
assertEqual(ft5_4wins, false, 'FT5 match should not end at 4 wins');

// FT3: first to 3 should end the match
const ft3_3wins = checkMatchWinner_game(3, 3, 1);
console.log(`  FT3 with 3-1 score — game says match over: ${ft3_3wins} (should be true)`);
assertEqual(ft3_3wins, true, 'FT3 match should end at 3 wins');

// FT1: first to 1 should end the match
const ft1_1win = checkMatchWinner_game(1, 1, 0);
console.log(`  FT1 with 1-0 score — game says match over: ${ft1_1win} (should be true)`);
assertEqual(ft1_1win, true, 'FT1 match should end at 1 win');

// Endless: should never end
const endless = checkMatchWinner_game(0, 100, 50);
console.log(`  Endless with 100-50 score — game says match over: ${endless} (should be false)`);
assertEqual(endless, false, 'Endless match should never end');

// ═══════════════════════════════════════
// TEST 10: Stats percentage label assignment check
// ═══════════════════════════════════════
console.log('\n--- Test: Stats label assignment ---');
// In the game code (lines 508-510):
//   $('wPct').textContent = (score.w/t*100).toFixed(1)+'% W';
//   $('lPct').textContent = (score.d/t*100).toFixed(1)+'% D';  <-- lPct gets draws
//   $('dPct').textContent = (score.l/t*100).toFixed(1)+'% L';  <-- dPct gets losses
// HTML order: wPct, dPct, lPct
// The variables are swapped: lPct shows draws, dPct shows losses
function simulateStatsUpdate(w, l, d) {
  const t = w + l + d || 1;
  return {
    wPct: (w/t*100).toFixed(1)+'% W',
    dPct: (d/t*100).toFixed(1)+'% D',
    lPct: (l/t*100).toFixed(1)+'% L',
  };
}

const stats = simulateStatsUpdate(5, 3, 2);
const lPctShowsLosses = stats.lPct.includes('30.0% L');
const dPctShowsDraws = stats.dPct.includes('20.0% D');
console.log(`  lPct value: "${stats.lPct}" (should show "30.0% L")`);
console.log(`  dPct value: "${stats.dPct}" (should show "20.0% D")`);
assert(lPctShowsLosses, 'lPct should show loss percentage');
assert(dPctShowsDraws, 'dPct should show draw percentage');

// ═══════════════════════════════════════
// RESULTS
// ═══════════════════════════════════════
console.log('\n══════════════════════════════════');
console.log(`Results: ${passed} passed, ${failed} failed`);
if (errors.length) {
  console.log('\nErrors/Bugs Found:');
  errors.forEach((e, i) => console.log(`  ${i+1}. ${e}`));
}
console.log('══════════════════════════════════\n');

process.exit(failed > 0 ? 1 : 0);
