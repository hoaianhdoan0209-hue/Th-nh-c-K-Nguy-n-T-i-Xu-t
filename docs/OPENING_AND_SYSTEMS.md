# Game 9 — approved opening and interconnected mechanics

Original story/world, inspired by knightly divine covenants. Gameplay benchmark: Ngọc Rồng Online (movement, multiplayer-style world, quest continuity, progression) but do not reuse its copyrighted art, characters or story.

## Plot

Asterion, 300 years after seven gods went silent. Villagers in Làng Tro Sáng live under dimming wards. A broken sword speaks to the player: an unknown divinity remembers a promise. The player begins as a nobody and forges the covenant by acting, not by receiving a god-class hero at level one.

## Roles (choose only ONE, custom name)

- Vệ Ước: 170 base HP, 80 MP, sturdy sword attack; skill **Thế Thủ** reduces incoming damage for a duration.
- Tinh Thuật Sư: 110 HP, 150 MP, ranged magic; skill **Ấn Tinh** hits foes at extended distance.
- Thánh Y: 130 HP, 130 MP, balanced staff; skill **Lời Nguyện** heals and purifies foes.

Each: three-strike normal combo, airborne jump, short dodge-dash, resource-aware skill with cooldown; level progression.

## First 10 minutes

1. Spawn in village; interact with elder **Bà Mộc**. Dialogue, no forced battle.
2. Gather three scattered **mảnh thần tích**; display count in quest HUD.
3. Bring them to **Thợ rèn Vân** and repair the broken sword.
4. Cross east into **Rừng Tàn Quang**; defeat three unique corrupted foes.
5. Purify the ancient altar and open the gate to **Đền Phong Ấn**.
6. Defeat **Kẻ Giữ Vực** after reading its telegraphed strike patterns.
7. Return to Bà Mộc, collect reward, receive First Covenant. World map reflects the altar’s restoration.

## Three zone thresholds

- Village x=0–1400, forest x=1400–2800, seal-temple x=2800–4200.
- No zone 2 access before sword repair, no zone 3 access before altar purification.
- NPCs: Bà Mộc, Thợ rèn Vân, merchant Nghi, scout Diệp.
- Pickup fragments, sword-repair gating, potions, shop, XP/levels and save/load must be functional.

## Quality test list

- [ ] New game > class selection > name > talk to elder without combat.
- [ ] Jump/platform physics and touch controls work.
- [ ] Three fragments appear, can pick once each, persist across saves.
- [ ] Smith only repairs if stage2 and three fragments.
- [ ] Forest gate blocks premature entry.
- [ ] Three monster types act and count exactly once per kill.
- [ ] A single boss fight has telegraph windows and a finish state.
- [ ] XP actually levels HP, MP and damage.
- [ ] Shop consumes gold and adds inventory potions, potion use restores HP.
- [ ] Reload game retains progress and world state.
- [ ] All UI fits mobile landscape and touch buttons do not swallow other input.
- [ ] A real iPhone Safari build plays all the way through.

These are **acceptance tests, not claims of passing**.
