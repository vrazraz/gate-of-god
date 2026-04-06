# 🎮 Lexica Spire - Game Design Document

**Version:** 1.0
**Last Updated:** February 13, 2026
**Project Type:** Educational Roguelike Deck-Builder
**Status:** Pre-Development

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Product Requirements Document (PRD)](#-product-requirements-document-prd)
3. [Core Gameplay Mechanics](#-core-gameplay-mechanics)
4. [Combat Mathematics & Algorithms](#-combat-mathematics--algorithms)
5. [Content Structure: Cards & Deck](#-content-structure-cards--deck)
6. [Boss Design: Act 1 Boss](#-boss-design-act-1-boss)
7. [Curses & Learning System](#-curses--learning-system)
8. [Events System](#-events-system)
9. [Economy & Meta-Progression](#-economy--meta-progression)
10. [Technical Architecture](#-technical-architecture)
11. [Art Style & UI/UX Concept](#-art-style--uiux-concept)
12. [Development Roadmap](#-development-roadmap)

---

## 🎯 Project Overview

### Concept Elevator Pitch

**Lexica Spire** is an innovative educational roguelike deck-builder that transforms English language learning into an engaging combat experience. Players battle through procedurally generated acts, where each card activation requires solving linguistic challenges—from grammar puzzles to vocabulary tests—all while managing strategic deck-building and resource optimization.

### Tagline
*"Master Language. Conquer the Spire."*

### Target Audience

- **Primary:** English learners (B1-C1 CEFR levels, ages 16-35)
- **Secondary:** Gamers interested in educational content
- **Tertiary:** Language teachers seeking engaging tools

### Genre & Key Features

- **Genre:** Roguelike Deck-Builder + Educational Game
- **Platform:** PC (Steam/Itch.io), potential mobile port
- **Session Length:** 30-60 minutes per run
- **Replayability:** High (procedural generation, deck variety, adaptive difficulty)

### Unique Selling Points

1. **True Integration:** Language learning IS the combat mechanic, not a separate layer
2. **Adaptive Difficulty:** Spaced repetition algorithm ensures personalized challenge
3. **Strategic Depth:** Roguelike mechanics meet vocabulary management
4. **Failure as Learning:** Every defeat creates targeted review opportunities

---

## 📄 Product Requirements Document (PRD)

### Vision Statement

Create a game where language mastery directly correlates to combat effectiveness, making learning feel powerful rather than tedious. Players should experience the same dopamine rush from successfully using the past perfect tense as they would from executing a perfect combo in a traditional game.

### Core Pillars

1. **Educational Integrity:** Every mechanic reinforces language learning
2. **Roguelike Excellence:** Satisfying strategic depth and replayability
3. **Adaptive Challenge:** Game difficulty matches player skill in real-time
4. **Meaningful Failure:** Mistakes become personalized learning opportunities

### Key Differentiators from Slay the Spire

| Feature | Slay the Spire | Lexica Spire |
|---------|----------------|--------------|
| **Card Activation** | Always available if energy permits | Requires solving linguistic challenge |
| **Damage Calculation** | Fixed values + modifiers | Performance-based (speed, accuracy) |
| **Status Effects** | Traditional buffs/debuffs | Language-themed (Confusion, Silence, Echo) |
| **Curses** | Random penalties | Mistakes you made, must be corrected |
| **Meta-Progression** | Unlocks only | Vocabulary expansion + skill trees |
| **Failure State** | Pure loss | Generates personalized review content |

### Success Metrics

**Educational KPIs:**
- Average vocabulary retention rate > 70% after 30 days
- Grammar accuracy improvement > 25% per Act completed
- Mistake repetition rate < 15% (successful spaced repetition)

**Gaming KPIs:**
- Session length: 30-60 minutes average
- Completion rate: 15-25% (standard for roguelikes)
- Return rate: >50% players complete 3+ runs

**Engagement KPIs:**
- Daily active users: Target 10k+ at 6 months post-launch
- Average runs per day: 2-3
- Steam review score: >85% positive

---

## ⚔️ Core Gameplay Mechanics

### 🎴 Combat System: "Syntax Strike"

Every turn, players draw cards and have 3 Energy to spend. Unlike traditional deck-builders, playing a card requires **solving a linguistic challenge** relevant to the card's theme.

#### Card Types

1. **Attack Cards** 🗡️
   - Deal direct damage to enemies
   - Challenges: Vocabulary matching, sentence completion, translation
   - Examples: "Vocabulary Strike", "Conjugation Slash"

2. **Skill Cards** 🛡️
   - Provide defense, draw, or utility
   - Challenges: Grammar correction, word ordering, preposition usage
   - Examples: "Tense Shield", "Article Block"

3. **Power Cards** ⚡
   - Persistent buffs lasting the entire combat
   - Challenges: Complex grammar, idiomatic expressions, essay correction
   - Examples: "Fluency Mastery", "Idiom Arsenal"

#### Card Activation Flow

```
Player plays card → Challenge appears → Player solves → Performance evaluated → Effect applies
```

**Challenge Types by Card:**
- **Vocabulary Cards:** Select correct definition, match synonyms, translate word
- **Grammar Cards:** Correct sentence, choose proper tense, fix word order
- **Listening Cards:** Type what you hear (audio clip)
- **Speaking Cards:** Pronounce word correctly (speech recognition, optional)

### 👾 Enemy Mechanic: "Linguistic Intent"

Enemies don't just attack—they inflict **language-based debuffs** that interfere with card challenges.

#### Enemy Debuffs

| Debuff | Effect | Visual Cue | Counter |
|--------|--------|-----------|---------|
| **Confusion** 🌀 | Typos inserted in challenge text | Wavy text | High Perception stat |
| **Silence** 🔇 | Audio challenges disabled | Muted speaker icon | Remove debuff with Skill cards |
| **Echo** 📢 | Must speak answer aloud (harder) | Microphone icon | Speaking skills or remove debuff |
| **Time Pressure** ⏰ | Reduced answer time (-50%) | Red timer | Calm Power card |
| **False Friends** 🎭 | Misleading cognates appear | Shifty eyes icon | Etymology knowledge |

**Enemy Intent Display:**
- Standard attack: Shows damage + any debuff
- Buff: Enemy prepares defensive stance
- Ultimate: Powerful attack with multi-debuff

### ⚖️ Answer Quality System

Performance determines card effectiveness:

| Quality | Time Limit | Effect Modifier | Consequences |
|---------|-----------|----------------|--------------|
| **Perfect Answer** ⭐ | < 2 seconds | +25% effect | Gain 1 Insight Point |
| **Correct Answer** ✅ | 2-10 seconds | 100% effect (base) | No bonus |
| **Slow Answer** 🐌 | 10-20 seconds | 75% effect | Gain 1 Fatigue (draw -1 next turn) |
| **Mistake** ❌ | Any | Card fizzles | Take 5 damage, add Curse to deck |

**Fatigue Mechanic:**
- Each Fatigue stack = -1 card drawn next turn (minimum 3)
- Removed at end of combat
- Encourages confident, quick answers

**Insight Points:**
- Earned from Perfect Answers
- Spent at Rest Sites for special training
- Meta-currency for unlocking advanced grammar modules

### 🗺️ Progression & Map Structure

**Act Structure:** (Similar to Slay the Spire)
- 3 Acts, each with 15-20 nodes
- Final boss at end of each Act
- True ending after Act 3

**Node Types:**

| Node | Icon | Purpose |
|------|------|---------|
| **Combat** ⚔️ | Red skull | Standard enemy encounter, earns Lex-Coins |
| **Elite Combat** 👿 | Red skull with horns | Harder fight, better rewards, Relic chance |
| **Library** 📚 | Open book | Choose card rewards, special vocabulary packs |
| **Rest Site** 🔥 | Campfire | Heal OR Study (remove Curse/upgrade card) |
| **Merchant** 💰 | Gold coin | Buy cards, remove cards, consult Tutor |
| **Random Event** ❓ | Question mark | Story events with choices |
| **Boss** 👑 | Crown | Act boss, major reward |

### 🏆 Relics System

Permanent passive bonuses found after Elite fights or events.

**Example Relics:**

- **The Golden Dictionary:** Perfect Answers restore 2 HP
- **Phonetic Ankh:** First mistake per combat doesn't fizzle the card
- **Etymology Lens:** See word origins during challenges (+10% accuracy)
- **Speed Reader's Monocle:** +2 seconds to answer timer
- **Polyglot's Amulet:** Start each combat with +1 Energy

---

## 🧮 Combat Mathematics & Algorithms

### Word Difficulty Algorithm

Each word has a dynamically calculated difficulty score:

$$D_w = \frac{\log_{10}(f) \cdot L}{C}$$

Where:
- $f$ = Word frequency rank (1 = most common, e.g., "the")
- $L$ = Word length (number of letters)
- $C$ = CEFR coefficient (A1=1.0, A2=1.2, B1=1.5, B2=1.8, C1=2.0, C2=2.5)

**Example Calculations:**

| Word | Frequency | Length | CEFR | Difficulty Score |
|------|-----------|--------|------|-----------------|
| "cat" | 500 | 3 | A1 (1.0) | 8.1 |
| "photosynthesis" | 50000 | 14 | C1 (2.0) | 32.9 |
| "pragmatic" | 15000 | 9 | B2 (1.8) | 23.1 |

**Usage:**
- Higher difficulty = more Lex-Coins on success
- Adaptive system increases difficulty as player improves

### Damage Formula

Card damage varies by player performance:

$$Damage = B \cdot \left(1 + \frac{S}{t}\right) \cdot M$$

Where:
- $B$ = Base damage (card value)
- $t$ = Time taken to answer (seconds)
- $S$ = Speed bonus multiplier (default 1.0)
- $M$ = Modifier (buffs/debuffs)

**Example:**
- Card: "Vocabulary Strike" (Base 10 damage)
- Answer time: 3 seconds
- Buffs: +50% damage modifier
- Calculation: $10 \cdot (1 + 1/3) \cdot 1.5 = 10 \cdot 1.33 \cdot 1.5 = 20$ damage

**Perfect Answer Bonus:**
- If $t < 2$: Additional +25% multiplicative bonus
- Encourages reflex learning of common patterns

### Adaptive Learning Algorithm (Spaced Repetition)

Lexica Spire uses a modified **SM-2 algorithm** (SuperMemo) to track vocabulary:

```python
# Simplified pseudocode
def calculate_next_appearance(word, quality):
    """
    quality: 0-5 scale
    0 = complete failure
    3 = correct with effort
    5 = perfect recall
    """
    if quality < 3:
        word.interval = 1  # Repeat soon
        word.add_curse()  # Mechanic trigger
    else:
        word.interval *= word.easiness_factor

    word.next_review = current_floor + word.interval
    word.easiness_factor += (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
```

**In-Game Translation:**
- Failed words → Become Curses in deck → Must be purged through correct usage
- Mastered words → Appear less frequently → Higher rarity card upgrades

### Curse Evolution System

Curses **intensify** if not addressed:

$$W_e = \sum_{i=1}^{n} (M_i \cdot R^{n})$$

Where:
- $W_e$ = Curse weight (higher = worse effect)
- $M_i$ = Mistake count for word $i$
- $R$ = Repetition multiplier (1.5)
- $n$ = Number of combat rounds since mistake

**Example:**
- Mistake on "irregular verbs" → "Echo of a Typo" Curse added (weight 1)
- Ignore for 5 combats → Weight becomes $1 \cdot 1.5^5 = 7.6$
- Curse now draws 2 cards instead of 1, both unusable

---

## 🃏 Content Structure: Cards & Deck

### Starting Deck: "The Polyglot"

Every run begins with these 10 cards:

| # | Card Name | Type | Cost | Effect | Challenge |
|---|-----------|------|------|--------|-----------|
| 1-4 | **Basic Strike** | Attack | 1 | Deal 6 damage | Match word to definition (A1 vocab) |
| 1-3 | **Basic Defend** | Skill | 1 | Gain 5 Block | Correct simple present tense |
| 1-2 | **Present Shield** | Skill | 1 | Gain 4 Block + Draw 1 card | Choose correct present form (is/am/are) |
| 1 | **Vocabulary Slash** | Attack | 2 | Deal 10 damage | Select synonym for given word |

**Design Philosophy:**
- Simple, forgiving challenges (A1-A2 level)
- Teaches core mechanics without overwhelming
- Deliberately weak to encourage card acquisition

### Card Rarity Distribution

**Common Cards (60% of pool):**
- Basic attacks/skills
- Single-concept challenges (one tense, one grammar rule)
- Examples: "Past Simple Strike", "Article Shield"

**Uncommon Cards (30% of pool):**
- Multi-concept challenges
- Stronger effects, conditional bonuses
- Examples: "Perfect Tense Barrage" (uses all perfect tenses), "Idiom Defense"

**Rare Cards (10% of pool):**
- Complex, high-reward cards
- Multi-step challenges or essay corrections
- Examples: "Subjunctive Mastery", "Discourse Analyzer"

### Example Card Designs

#### 🗡️ **Vocabulary Strike** (Common, Attack)
- **Cost:** 1 Energy
- **Effect:** Deal 8 damage
- **Challenge:** "Select the correct definition of: **[target word]**"
  - 4 multiple choice options
  - Time limit: 10 seconds
- **Upgrade:** +3 damage, word difficulty increases

---

#### 🛡️ **Tense Shield** (Common, Skill)
- **Cost:** 1 Energy
- **Effect:** Gain 7 Block
- **Challenge:** "Conjugate **[verb]** in **[tense]**"
  - Free text input
  - Accepts variations (contractions, full forms)
- **Upgrade:** +2 Block, accepts 2 tenses

---

#### ⚡ **Fluency Aura** (Rare, Power)
- **Cost:** 3 Energy
- **Effect:** **Perfect Answers heal 3 HP. Lasts all combat.**
- **Challenge:** "Correct all 5 grammar errors in this paragraph:"
  - Text block with typos, tense errors, article mistakes
  - Time limit: 30 seconds
- **Upgrade:** Heal 5 HP instead

---

#### 🔥 **Irregular Inferno** (Uncommon, Attack)
- **Cost:** 2 Energy
- **Effect:** Deal 4 damage 3 times
- **Challenge:** "Provide the past simple of these irregular verbs:"
  - 3 verbs shown (e.g., "go", "see", "take")
  - Must answer all correctly
- **Upgrade:** Deal 5 damage 3 times

---

### Deck Building Strategy

**Archetypes:**

1. **Speed Demon:** Low-cost cards, focuses on Perfect Answers, relies on speed bonuses
2. **Grammar Tank:** High-block skills, defensive Powers, tolerates Slow Answers
3. **Vocabulary Burst:** High-damage attacks, accepts mistakes for big payoff
4. **Hybrid Learner:** Balanced mix, adapts to enemy types

**Synergies:**
- **Tense Mastery** (Power) + Tense-based attacks = reduced challenge difficulty
- **Etymology Lens** (Relic) + Rare vocabulary cards = higher accuracy
- **Speed Reader's Monocle** (Relic) + Speed Demon archetype = devastating combos

---

## 👑 Boss Design: Act 1 Boss

### **Ашипу** (Одержимый верховный жрец)

**Concept:** A ancient guardian who imprisons those who misuse time-related language. A towering figure in judge robes, holding a gavel that strikes different "eras."

**Visual Design:**
- Body: Stone statue with clockwork mechanisms visible
- Head: Three faces (Past/Present/Future), rotates based on phase
- Weapon: Gavel that shifts color (sepia/white/cyan) per era
- Arena: Circular courtroom with floating verb conjugation tables

---

### Stats

- **HP:** 250
- **Actions per Turn:** 3 (rare for Act 1 boss)
- **Phases:** 3 distinct eras

---

### Unique Mechanic: "Temporal Shift"

Every 3 turns, the boss changes era. The active era modifies ALL card challenges:

#### 🟤 **Past Era**
- **Effect:** All challenges require past tenses (simple/continuous/perfect)
- **Visual:** Arena turns sepia, clock ticks backward
- **Player Adaptation:** Past-tense cards become easier, present/future harder

#### ⚪ **Present Era**
- **Effect:** Standard challenges (default game state)
- **Visual:** Normal lighting, clock ticks normally
- **Player Adaptation:** No modifications

#### 🔵 **Future Era**
- **Effect:** All challenges require future forms (will/going to/future perfect)
- **Visual:** Arena glows cyan, clock ticks forward rapidly
- **Player Adaptation:** Future-tense cards become easier

---

### Ability Rotation

| Turn | Ability | Effect | Intent Display |
|------|---------|--------|----------------|
| 1 | **Grammar Slam** | 12 damage + Confusion (2 turns) | Attack + Debuff |
| 2 | **Irregular Strike** | 8 damage × 2 | Attack × 2 |
| 3 | **Temporal Shift** | Change era, gain 15 Block | Buff |
| 4 | **Verdict of Silence** | 6 damage + Silence (3 turns) | Attack + Debuff |
| 5 | **Timeline Reset** | Shuffle 2 Curses into player deck | Curse |
| 6 | **Grammar Slam** | 15 damage + Confusion | Attack + Debuff |
| Repeat | Cycle continues with +2 damage per loop | — | — |

---

### Ultimate Phase: "The Great Exam" (25% HP)

When below 63 HP (25%), the boss enters desperation mode:

**The Great Exam Ability:**
- **Trigger:** One-time when HP drops below 25%
- **Effect:**
  - Boss gains 30 Block
  - Player must construct a **grammatically perfect sentence** using:
    - 1 provided subject
    - 1 verb (must be conjugated in the current era's tense)
    - 1 object
    - 1 time marker (yesterday/now/tomorrow)
  - Time limit: 45 seconds
- **Success:** Deal 25 damage to boss, remove all debuffs
- **Failure:** Take 20 damage, gain 3 random Curses

**Example Challenge (Past Era):**
- Subject: "The students"
- Verb: "study" (must use past tense)
- Object: "grammar"
- Time marker: "yesterday"
- Correct answer: "The students studied grammar yesterday."

---

### Reward

Upon defeat, player receives:

1. **Relic: The Golden Dictionary**
   - *"Perfect Answers restore 3 HP. Your words carry weight."*
   - Synergizes with speed-focused decks

2. **Choice of 3 Rare Cards** (from Tense/Grammar pool)

3. **100 Lex-Coins**

4. **Unlock:** Act 2 access + "Temporal Awareness" (passive: see boss intents 1 turn ahead)

---

### Strategy Tips

- **Build Preparation:** Include diverse tense cards before this fight
- **Relic Choices:** "Speed Reader's Monocle" counters Confusion debuff
- **Timing:** Save high-block cards for turns 1 and 6 (Grammar Slam)
- **Ultimate Strategy:** Practice sentence construction beforehand at Rest Sites

---

## 🪦 Curses & Learning System

### Philosophy: "Linguistic Debts"

In Lexica Spire, **Curses represent mistakes you haven't corrected yet**. Unlike traditional roguelike curses (random penalties), every Curse is tied to a specific word/grammar rule you failed.

**Core Principle:** *"Your errors follow you until you master them."*

---

### How Curses Are Added

1. **Combat Mistakes:** Answer a challenge incorrectly → relevant Curse added
2. **Event Penalties:** Poor choices in events can curse you
3. **Boss Abilities:** Some bosses shuffle Curses into deck
4. **Relic Side Effects:** Powerful relics may come with Curse costs

---

### Curse Types

#### 🌀 **Echo of a Typo**
- **Trigger:** Misspelled a word during typing challenge
- **Effect:** Unplayable card that exhausts when drawn
- **Purge Method:** Spell the word correctly 3 times in combat
- **Visual:** Scrambled letters floating on card

---

#### 🎭 **False Friend**
- **Trigger:** Confused cognate (e.g., "embarazada" ≠ "embarrassed")
- **Effect:** Random card in hand shows misleading definition
- **Purge Method:** Identify the false friend in a challenge
- **Visual:** Card with shifty eyes

---

#### ⛓️ **Syntax Chains**
- **Trigger:** Failed grammar sequencing (word order)
- **Effect:** Two random cards become linked—must play both or neither
- **Purge Method:** Correctly order a complex sentence
- **Visual:** Two cards chained together

---

#### 🌫️ **Tense Fog**
- **Trigger:** Used wrong tense in challenge
- **Effect:** All Skill cards cost +1 Energy
- **Purge Method:** Use correct tense 5 times in one combat
- **Visual:** Foggy overlay on Skill cards

---

#### 📢 **Pronunciation Hex**
- **Trigger:** Failed a speaking challenge (if enabled)
- **Effect:** First card each turn requires spoken activation
- **Purge Method:** Speak 10 words correctly in one run
- **Visual:** Microphone icon on card

---

### Curse Intensification Algorithm

Curses don't stay static—they **evolve** if ignored:

$$I_c = \lfloor \frac{T_c}{5} \rfloor$$

Where:
- $I_c$ = Curse intensity level (0-5)
- $T_c$ = Number of turns (combat rounds) curse has existed

**Intensity Effects:**

| Level | Turns Existed | Effect Change |
|-------|--------------|---------------|
| 0 | 0-4 | Base effect |
| 1 | 5-9 | Effect doubles (e.g., 1 exhausted card → 2) |
| 2 | 10-14 | Effect triples + adds secondary penalty |
| 3 | 15-19 | Curse spreads (affects adjacent cards) |
| 4 | 20-24 | Permanent until purged (can't be removed at shop) |
| 5 | 25+ | **Corrupted Curse:** Randomly activates each turn |

**Strategic Implication:** Players must prioritize learning their mistakes or face cascading difficulty.

---

### Purification Methods

#### 1️⃣ **Active Learning (Combat)**
- **Method:** Correctly answer the challenge that created the Curse
- **Occurrence:** Challenge appears randomly when Curse is drawn
- **Cost:** Free
- **Risk:** Fail again → Curse intensifies by +1 level
- **Best For:** Common mistakes you're ready to fix

---

#### 2️⃣ **Study (Rest Site)**
- **Method:** Spend rest turn studying the Curse topic
- **Occurrence:** Choose "Study" instead of "Heal" at campfire
- **Cost:** Lose healing opportunity
- **Effect:** Remove 1 Curse, practice challenges, gain +1 Insight Point
- **Best For:** High-intensity Curses or pre-boss preparation

---

#### 3️⃣ **The Tutor (Merchant)**
- **Method:** Pay Lex-Coins to remove Curse
- **Cost:** $50 + (25 \cdot I_c)$ Lex-Coins
  - Level 0 Curse: 50 coins
  - Level 2 Curse: 100 coins
  - Level 5 Curse: 175 coins
- **Effect:** Instant removal, no learning benefit
- **Best For:** Emergency curse removal when economy is strong

---

#### 4️⃣ **Curse Conversion (Event)**
- **Method:** Rare event "The Alchemist's Lab"
- **Effect:** Transform Curse into a related **Lesson Card** (playable)
- **Cost:** 20% max HP
- **Example:** "Tense Fog" → "Temporal Clarity" (Skill: Gain Block equal to tenses you know)
- **Best For:** Turning weakness into strength

---

### Curse Synergies & Meta

**Some builds embrace Curses:**

- **Relic: Cursed Quill**
  - *"Cards cost -1 Energy for each Curse in deck."*
  - Strategy: Hoard low-intensity Curses for energy advantage

- **Card: Embrace Ignorance (Rare Power)**
  - *"Whenever you draw a Curse, deal 10 damage to a random enemy."*
  - Strategy: Curse-focused burn deck

- **Event: Deal with the Devil (Grammar Edition)**
  - Gain powerful Relic but add 5 permanent Curses
  - High-risk, high-reward for advanced players

---

### Curse UI Design

**Deck View:**
- Curses highlighted in **sickly green glow**
- Intensity level shown as chain links (⛓️ × level)
- Tooltip shows:
  - Original mistake
  - Turns existed
  - Purification methods available

**In Combat:**
- Curse card draws have **cracking sound effect**
- Screen flashes when Curse intensifies
- Boss dialogue mocks you for carrying Curses ("Still struggling with past tense, I see...")

---

## 🎲 Events System

### Philosophy: "The Educational Casino"

Events in Lexica Spire aren't random trivia—they're **high-stakes learning gambles**. Every event presents:
1. A linguistic challenge
2. Multiple approaches (risk vs. reward)
3. Consequences tied to language mastery

**Design Goal:** Make events feel like meaningful tests of skill, not arbitrary luck.

---

### Event Categories

1. **Knowledge Tests:** Direct challenges with clear pass/fail
2. **Risk/Reward:** Gamble your skills for better rewards
3. **Story Encounters:** Narrative choices that require language understanding
4. **Curse Generators:** Tempting shortcuts with linguistic costs

---

## 📚 Event Example 1: "The Library of Forgotten Idioms"

**Setting:** You discover an ancient library where books whisper idioms.

**Text:**
> *A dusty librarian emerges from the shelves. "To enter the archives, you must prove your understanding of our... more colorful expressions. Choose wisely."*

**Options:**

### Option A: "Take the Test" 🎓
- **Challenge:** Match 5 idioms to their meanings
  - Example: "Break the ice" → [ ] Start a conversation / [ ] Destroy frozen water
- **Time Limit:** 60 seconds
- **Rewards (Success):**
  - Remove 1 Curse
  - Gain Relic: **"Bookworm's Glasses"** (+2 seconds to all reading challenges)
  - +50 Lex-Coins
- **Penalty (Failure):**
  - Gain Curse: **"Literal Mind"** (Idiom cards cost +1 Energy)
  - Lose 10 HP

---

### Option B: "Skip the Test, Bribe the Librarian" 💰
- **Cost:** 100 Lex-Coins
- **Effect:**
  - Gain 3 Common idiom cards
  - No learning challenge
  - Librarian mutters: "Knowledge bought is knowledge forgotten..."
- **Hidden Consequence:** 25% chance those cards become Cursed (unplayable until purged)

---

### Option C: "Leave Respectfully" 🚪
- **Cost:** None
- **Effect:**
  - Heal 10 HP
  - Gain 1 Insight Point
  - Librarian nods approvingly

---

## 💀 Event Example 2: "The Slang Merchant"

**Setting:** A shady figure offers to teach you "real" English—street slang.

**Text:**
> *"Yo, forget that textbook nonsense. I got the good stuff—slang that'll make you sound REAL. But it's risky, ya feel me?"*

**Options:**

### Option A: "Learn 3 Slang Terms" 🎤
- **Effect:** Add 3 **"Slang Attack"** cards to deck
  - **Slang Attack:** Deal 12 damage, BUT must use slang correctly in context
  - Challenge: "Use **'lit'** in a sentence about a party."
- **Risk Algorithm:**
  $$P_{fail} = 0.3 - (0.05 \cdot C)$$
  Where $C$ = CEFR level (C1 players have 25% fail rate, B1 have 30%)
- **Penalty (Misuse):** Card deals damage to YOU instead

---

### Option B: "Buy Just One Slang Card" 💵
- **Cost:** 40 Lex-Coins
- **Effect:** Choose 1 slang card, lower risk (15% failure rate)

---

### Option C: "Reject Slang" 🙅
- **Effect:**
  - Merchant laughs: "Suit yourself, nerd."
  - Gain **"Formal Speech"** buff: +10% accuracy on grammar challenges (rest of Act)

---

## 🪞 Event Example 3: "The Mirror of True Self"

**Setting:** A magical mirror shows your "linguistic shadow"—all the mistakes you've made.

**Text:**
> *The mirror ripples. A shadowy figure emerges—it looks like you, but speaks in broken English. "Face me, or run from your failures."*

**Options:**

### Option A: "Fight Your Shadow" ⚔️
- **Effect:** Enter special combat
  - Enemy: **Shadow Self** (HP = your current Curse count × 10)
  - Enemy deck = copies of YOUR Cursed cards
  - Win: Remove ALL Curses from deck
  - Lose: Gain 2 additional Curses + lose 25% gold

---

### Option B: "Acknowledge Mistakes" 🙏
- **Challenge:** Write a short paragraph (50 words) in English about what you struggle with
  - Evaluated by grammar checker (lenient, focuses on honesty)
- **Reward (Success):**
  - Remove 1 Curse of your choice
  - Gain Insight Point
  - Mirror whispers: "Growth begins with honesty."
- **Penalty (Fail):** Gain Curse: **"Denial"** (Can't remove Curses at shops)

---

### Option C: "Shatter the Mirror" 🔨
- **Effect:**
  - Deal 10 damage to self
  - Gain Relic: **"Broken Reflection"** (Curses become Ethereal—disappear at end of turn)
  - Merchant events cost 20% more (you're avoiding reality)

---

## 🎵 Event Example 4: "The Broken Gramophone"

**Setting:** An old phonograph plays crackling audio—a listening comprehension test.

**Text:**
> *The gramophone sputters to life. A voice speaks rapidly through static: "If you can understand me, you may take the treasure. Fail, and... well, the static gets louder."*

**Options:**

### Option A: "Listen Carefully" 👂
- **Challenge:** Transcribe a 15-second audio clip
  - Played 2 times
  - Contains 2-3 complex words (B2-C1 level)
  - Must get 80% accuracy
- **Reward (Success):**
  - Relic: **"Tuned Ear"** (Audio challenges give +5 seconds)
  - +75 Lex-Coins
- **Penalty (Fail):**
  - Gain debuff: **"Tinnitus"** (Audio challenges disabled for 3 combats)
  - Lose 15 HP

---

### Option B: "Use Subtitles" 📝
- **Challenge:** Same audio, but with visual text (easier)
- **Reward (Success):**
  - +50 Lex-Coins
  - Gain 1 Common card
- **Note:** Lower reward reflects lower difficulty

---

### Option C: "Smash the Gramophone" 🔨
- **Effect:**
  - Gain Curse: **"Deaf Ear"** (Audio challenges auto-fail for rest of run)
  - Gain Relic: **"Scrap Metal"** (Sell for 100 Lex-Coins at shop)
  - Flavor text: "Some lessons are too painful to hear."

---

### Event Design Principles

✅ **Always Provide Outs:** No "trap" events—every option has merit
✅ **Tie to Learning:** Challenges must teach, not frustrate
✅ **Risk Transparency:** Show probabilities when possible
✅ **Narrative Flavor:** Events tell a story about language learning journey
✅ **Meta Choices:** Some events unlock future opportunities (e.g., Tutor NPC appears later if you helped him)

---

## 💰 Economy & Meta-Progression

### Currency System

#### 💵 **Lex-Coins** (Primary Currency)
- **Earned From:**
  - Combat victories: 20-40 coins per fight (scales with difficulty)
  - Perfect Answers: +5 bonus coins per perfect
  - Events: Variable rewards (25-100 coins)
  - Selling cards: 25% of purchase price
- **Spent On:**
  - Cards (50-150 coins based on rarity)
  - Card removal (75 coins, increases +25 per removal)
  - Relics (rare, 150-300 coins)
  - Curse removal (50-175 coins based on intensity)
  - Tutor services (100 coins for boss tips)

**Economy Balance:**
- Average run earnings: 600-800 coins (no meta bonuses)
- Key purchases needed: 2-3 card removals, 1-2 relics, curse management
- Forces strategic spending decisions

---

#### 💡 **Insight Points** (Meta-Progression Currency)
- **Earned From:**
  - Perfect Answers: +1 per perfect
  - Completing Acts: +10 per Act
  - Story events: +1-3 per event
  - Achievements: Variable rewards
- **Spent On (Between Runs):**
  - Unlocking new starting decks (50 points)
  - Expanding vocabulary database (25 points per tier)
  - Upgrading meta-relics (30-100 points)
  - Purchasing retries on failed runs (20 points = continue from last rest)

**Meta-Progression Philosophy:** Insight Points should feel earned, not grindy. Average player unlocks 1 major upgrade per 3-4 runs.

---

### Shop System: "The Tutor's Academy"

**Shop Types:**

#### 🏪 **Standard Merchant** (Common Node)
**Inventory:**
- 5 random cards (Common-Rare mix)
- 2 relics (if available)
- Card removal service
- Curse removal service

**Dynamic Pricing:**
- **Difficulty Tax:** Higher CEFR level cards cost more
- **Demand Pricing:** If you've bought 3+ attacks, attack cards cost +20%
- **Bulk Discount:** Buy 3 cards → 10% off total

---

#### 🎓 **The Tutor's Consultation** (Event/Elite Reward)
**Services:**
1. **Boss Strategy Guide** (100 coins)
   - Shows boss abilities before fight
   - Recommends 3 cards for matchup
   - Discount on those cards (25% off)

2. **Deck Analysis** (50 coins)
   - AI evaluates your deck synergy
   - Suggests 1 card to remove, 1 to add
   - Gives accuracy prediction for next fight

3. **Grammar Insurance** (75 coins)
   - Next mistake won't add Curse
   - One-time use
   - Expires at next rest

4. **Mnemonic Device** (150 coins, permanent)
   - Choose 1 word/grammar rule
   - Challenges for that rule become 50% easier
   - Limit: 3 per run

---

### Unique Economic Mechanics

#### 💸 **Linguistic Betting** (Event)
**Mechanic:**
> *An NPC challenges you: "I bet you can't use 'subjunctive mood' correctly in a sentence. 100 coins says you fail."*

**Player Choice:**
- **Accept Bet:** If correct, win 100 coins + bet doubles for next challenge
- **Decline:** No risk, no reward
- **Counter-Bet:** Wager YOUR coins (up to 200) for 2x payout

**Risk-Reward Math:**
$$E_v = P_{success} \cdot (Bet \cdot 2) - P_{failure} \cdot Bet$$

For 70% accuracy player:
$E_v = 0.7 \cdot 200 - 0.3 \cdot 100 = 140 - 30 = +110$ expected coins (worth it!)

---

#### 🔄 **Card Transmutation** (Rare Event)
**Mechanic:**
- Combine 3 cards of same rarity → 1 card of higher rarity
- Example: 3 Common Attacks → 1 Uncommon Attack of your choice
- **Cost:** 50 Lex-Coins + 1 Curse added (represents "skipping" learning)

**Strategic Use:**
- Endgame deck refinement
- Fixing bad RNG (too many skills, no attacks)
- Enables "infinite scaling" builds (rare + rare + rare → guaranteed boss-killer)

---

#### 🏦 **The Vocabulary Bank** (Meta-Progression)
**Mechanic (Between Runs):**
- Deposit Insight Points to earn "interest"
- For every 10 points deposited, earn +1 point per Act completed in future runs
- Max deposit: 50 points (earn +5 per Act = +15 per full run)

**Example:**
- Run 1: Deposit 30 points
- Run 2: Complete Act 1 → Earn +3 bonus points
- Run 2: Complete Act 2 → Earn +3 more = 6 total
- Run 3: Complete full game → Earn +9 points

**Strategic Implication:** Delayed gratification for long-term gains.

---

### Meta-Progression: "The Library of Mastery"

**Unlockable Upgrades (Permanent):**

#### 📖 **Vocabulary Tiers**
- **Tier 1 (Unlocked):** A1-B1 vocabulary (1000 words)
- **Tier 2 (25 Insight):** B2 vocabulary (+1500 words)
- **Tier 3 (50 Insight):** C1 vocabulary (+2000 words)
- **Tier 4 (100 Insight):** C2 vocabulary (+3000 words)

**Effect:** Higher tiers = harder challenges but better rewards (+25% Lex-Coins per tier)

---

#### 🧠 **Grammar Modules**
- **Unlock Past Perfect:** 20 Insight
- **Unlock Subjunctive Mood:** 35 Insight
- **Unlock Passive Voice:** 30 Insight
- **Unlock Conditionals (All Types):** 40 Insight

**Effect:** Unlocks themed card pools + challenges using those grammar rules

---

#### 💪 **Mental Endurance**
- **Level 1 (15 Insight):** +2 seconds to all timers
- **Level 2 (30 Insight):** Start with +1 Insight Point per run
- **Level 3 (50 Insight):** First mistake per combat doesn't fizzle card

---

#### 🎴 **Alternate Starting Decks**
- **The Minimalist (30 Insight):** 5 cards, all Rare, harder challenges
- **The Conversationalist (40 Insight):** 15 cards, focuses on speaking challenges
- **The Academic (50 Insight):** 12 cards, Power-heavy, grammar-focused

---

### Economy Balancing Formula

**Target Earnings Per Act:**
$$E_a = (C_f \cdot 15) + (P_a \cdot 5 \cdot A_c)$$

Where:
- $C_f$ = Coins per fight (base 30)
- $P_a$ = Perfect Answer rate (0.0-1.0)
- $A_c$ = Average cards drawn per fight (10)

**Example (Skilled Player):**
- 15 fights × 30 coins = 450 base
- 0.7 perfect rate × 5 coins × 150 cards = +525 bonus
- Total: **975 coins per Act**

**Spending Targets:**
- Act 1: 300 coins (1 relic, 2 removals)
- Act 2: 400 coins (cards, curse removal)
- Act 3: 275 coins (boss prep)
- **End surplus:** ~0-100 coins (tight but fair)

---

## 🖥️ Technical Architecture

### Recommended Technology Stack

#### **Frontend (Game Engine)**
**Primary Recommendation: Godot 4.x**
- **Pros:**
  - Free, open-source
  - Excellent 2D support (pixel-perfect rendering)
  - GDScript easy to learn, C# also supported
  - Built-in UI system (crucial for text-heavy game)
  - Cross-platform export (Steam, Itch.io, mobile)
- **Cons:**
  - Smaller community than Unity
  - Fewer marketplace assets

**Alternative: Unity 2022 LTS**
- **Pros:**
  - Massive asset store (card game templates)
  - Superior debugging tools
  - More learning resources
- **Cons:**
  - Licensing costs for revenue > $200k
  - Heavier builds

**Tech Stack for Godot:**
```
Godot 4.2 (Game Engine)
├── GDScript (Core logic)
├── JSON (Card/Enemy data)
├── SQLite (Local save data)
└── HTTP requests to Python backend
```

---

#### **Backend (Linguistic Engine)**
**Python + FastAPI**

**Why Python:**
- NLP libraries (spaCy, NLTK) for grammar checking
- Speech recognition (Vosk, Whisper API)
- ML for adaptive difficulty (scikit-learn)
- Dictionary APIs easy to integrate

**Architecture:**
```python
FastAPI Backend
├── /api/validate-answer (POST)
│   ├── Grammar checker (LanguageTool)
│   ├── Vocabulary lookup (WordNet)
│   └── Pronunciation check (Vosk)
├── /api/generate-challenge (POST)
│   ├── Spaced repetition algorithm
│   ├── Difficulty adjuster
│   └── Word frequency database
└── /api/player-progress (GET/POST)
    ├── Save/load deck state
    └── Analytics tracking
```

**Example Endpoint:**
```python
@app.post("/api/validate-answer")
def validate_answer(
    challenge_type: str,
    user_answer: str,
    correct_answer: str,
    time_taken: float
):
    # Grammar check
    if challenge_type == "grammar":
        errors = grammar_checker.check(user_answer)
        is_correct = len(errors) == 0

    # Calculate performance
    quality = calculate_quality(is_correct, time_taken)

    # Update spaced repetition
    update_word_stats(challenge_id, quality)

    return {
        "correct": is_correct,
        "quality": quality,
        "feedback": generate_feedback(errors)
    }
```

---

#### **Database: PostgreSQL**
**Schema Design:**

**Table: `players`**
```sql
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    cefr_level VARCHAR(2), -- A1, B2, C1, etc.
    insight_points INT DEFAULT 0,
    runs_completed INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Table: `vocabulary_stats`**
```sql
CREATE TABLE vocabulary_stats (
    player_id INT REFERENCES players(id),
    word VARCHAR(100),
    correct_count INT DEFAULT 0,
    mistake_count INT DEFAULT 0,
    last_seen TIMESTAMP,
    interval FLOAT, -- Spaced repetition interval
    easiness_factor FLOAT DEFAULT 2.5,
    PRIMARY KEY (player_id, word)
);
```

**Table: `run_history`**
```sql
CREATE TABLE run_history (
    id SERIAL PRIMARY KEY,
    player_id INT REFERENCES players(id),
    deck_json TEXT, -- Full deck state
    floor_reached INT,
    curses_active INT,
    victory BOOLEAN,
    timestamp TIMESTAMP DEFAULT NOW()
);
```

---

### External APIs & Services

#### 1. **Dictionary API**
**Recommended: Free Dictionary API**
- Endpoint: `https://api.dictionaryapi.dev/api/v2/entries/en/{word}`
- Provides: Definitions, phonetics, examples
- Rate Limit: Unlimited (open-source)

**Alternative: Oxford Dictionary API** (Paid, better quality)

---

#### 2. **Grammar Checker**
**LanguageTool API**
- Endpoint: `https://api.languagetool.org/v2/check`
- Detects: Grammar, spelling, style issues
- Free tier: 20 requests/minute

**Self-Hosted Option:**
```python
import language_tool_python
tool = language_tool_python.LanguageTool('en-US')
matches = tool.check("Your sentence here.")
```

---

#### 3. **Speech Recognition (Optional)**
**Vosk (Offline)**
- Pros: Free, no API calls, privacy-friendly
- Cons: Lower accuracy than cloud services
- Use case: Echo debuff, speaking challenges

**Whisper API (OpenAI)** (Paid, better quality)
- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Cost: $0.006/minute

---

### Data Structures

#### **Card Schema (JSON)**
```json
{
  "id": "vocab_strike_01",
  "name": "Vocabulary Strike",
  "type": "attack",
  "rarity": "common",
  "cost": 1,
  "base_effect": {
    "damage": 8,
    "target": "single"
  },
  "challenge": {
    "type": "vocabulary",
    "difficulty": "B1",
    "question_template": "Select the definition of: {word}",
    "answer_type": "multiple_choice",
    "options_count": 4,
    "time_limit": 10
  },
  "upgrade": {
    "damage": 11,
    "difficulty": "B2"
  }
}
```

#### **Enemy Schema (JSON)**
```json
{
  "id": "utgallu",
  "name": "Утгалу",
  "hp": 40,
  "ai_pattern": [
    {"turn": 1, "action": "attack", "value": 7},
    {"turn": 2, "action": "debuff", "type": "confusion", "duration": 2},
    {"turn": 3, "action": "attack", "value": 9}
  ],
  "loot": {
    "coins": [20, 30],
    "card_drops": ["common", "common"]
  }
}
```

---

### Key Systems Implementation

#### **Spaced Repetition Engine**
```python
class SpacedRepetition:
    def calculate_next_review(self, word_stats, quality):
        """
        quality: 0-5 (0=wrong, 5=perfect)
        """
        if quality < 3:
            word_stats['interval'] = 1
            return 1  # Review immediately (add Curse)

        # SM-2 Algorithm
        word_stats['easiness_factor'] += (
            0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
        )
        word_stats['easiness_factor'] = max(1.3, word_stats['easiness_factor'])

        word_stats['interval'] *= word_stats['easiness_factor']
        return int(word_stats['interval'])
```

---

#### **Adaptive Difficulty System**
```python
def adjust_challenge_difficulty(player_stats):
    """
    Dynamically adjust CEFR level based on performance
    """
    recent_accuracy = player_stats['last_20_answers'].count(True) / 20

    if recent_accuracy > 0.85:
        # Player is too comfortable, increase difficulty
        return increase_cefr_level(player_stats['current_level'])
    elif recent_accuracy < 0.60:
        # Player is struggling, decrease difficulty
        return decrease_cefr_level(player_stats['current_level'])
    else:
        return player_stats['current_level']
```

---

#### **Challenge Generation Algorithm**
```python
def generate_challenge(card_data, player_level):
    """
    Creates a challenge instance from card template
    """
    if card_data['challenge']['type'] == 'vocabulary':
        # Fetch word from frequency database
        word = get_word_by_difficulty(
            player_level,
            card_data['challenge']['difficulty']
        )

        # Generate distractors (wrong answers)
        distractors = get_similar_words(word, count=3)
        correct_def = get_definition(word)

        return {
            'question': f"What does '{word}' mean?",
            'options': shuffle([correct_def] + distractors),
            'correct_index': 0,  # Shuffled internally
            'time_limit': card_data['challenge']['time_limit']
        }
```

---

### Performance Optimization

**Critical Optimizations:**
1. **Card Pool Preloading:** Load all 100+ cards at startup, cache in RAM
2. **Challenge Generation:** Pre-generate 5 challenges per card type (reduce API calls)
3. **Audio Caching:** Download pronunciation files on first use, store locally
4. **Database Connection Pooling:** Reuse PostgreSQL connections (10-20 pool size)

**Target Performance:**
- Challenge generation: < 0.5 seconds
- Answer validation: < 0.2 seconds
- Card draw/play animation: 60 FPS locked

---

## 🎨 Art Style & UI/UX Concept

### Visual Style Direction

**Core Aesthetic:** *Academic Gothic meets Roguelike Dungeon*

**Inspirations:**
- **Slay the Spire:** Hand-drawn, painterly style with exaggerated proportions
- **Darkest Dungeon:** High-contrast, dramatic lighting
- **Inscryption:** Occult academic vibes (books, candles, mysterious artifacts)

---

### Color Palette

**Primary Colors:**

| Element | Hex Code | Usage |
|---------|----------|-------|
| **Parchment** | #F4E8D0 | Backgrounds, card bases |
| **Ink Black** | #1A1A1A | Text, outlines, shadows |
| **Academic Blue** | #2E5090 | Skill cards, UI accents |
| **Crimson Red** | #8B1E1E | Attack cards, damage indicators |
| **Gold Leaf** | #D4AF37 | Rare cards, Lex-Coins, highlights |
| **Emerald Green** | #2D5F3F | Power cards, positive buffs |
| **Curse Purple** | #5A3E5C | Curses, debuffs, danger zones |

**Mood:** Warm, inviting, but with edge of difficulty (not childish).

---

### Card Visual Design

**Structure:**
```
┌─────────────────────┐
│   [CARD NAME]       │ ← Gold foil for Rare, simple text for Common
├─────────────────────┤
│                     │
│   [ILLUSTRATION]    │ ← Hand-drawn character/concept art
│                     │
├─────────────────────┤
│ [COST]   [TYPE]     │ ← Energy icon + Attack/Skill/Power icon
├─────────────────────┤
│ Effect text here    │ ← Concise, uses game terminology
│ Challenge: Grammar  │ ← Icon for challenge type
└─────────────────────┘
```

**Rarity Indicators:**
- **Common:** Plain parchment border
- **Uncommon:** Silver filigree corners
- **Rare:** Gold border + foil effect on illustration

**Example Visual Description:**
- **Card:** "Tense Shield"
- **Illustration:** Knight holding shield with clock faces on it
- **Challenge Icon:** Pencil + clock (grammar + timed)
- **Effect Text:** "Gain 7 Block. Challenge: Conjugate verb in [tense]."

---

### UI/UX Principles

#### 1. **Clarity Over Complexity**
- Text must be **highly readable** (16pt minimum for body text)
- Challenges displayed in **center screen, full focus**
- No distracting animations during answer input

#### 2. **Instant Feedback**
- **Correct Answer:** Green checkmark + satisfying "ding" sound
- **Incorrect Answer:** Red X + card "fizzles" with crumbling effect
- **Perfect Answer:** Gold star burst + bonus coin visual

#### 3. **Accessibility**
- **Colorblind Mode:** Icons + text labels for all status effects
- **Dyslexia-Friendly Font:** OpenDyslexic option in settings
- **Adjustable Text Size:** 100%-150% scale
- **Audio Descriptions:** Optional TTS for card text

#### 4. **Challenge Presentation**

**Example: Vocabulary Challenge UI**
```
┌────────────────────────────────────┐
│  What does "ubiquitous" mean?      │ ← Question in large font
├────────────────────────────────────┤
│                                    │
│  A) Rare and valuable              │ ← Answer buttons (big targets)
│  B) Found everywhere               │
│  C) Dangerous                      │
│  D) Ancient                        │
│                                    │
├────────────────────────────────────┤
│  Time: ████████░░ 7s               │ ← Timer bar (green → yellow → red)
└────────────────────────────────────┘
```

**Example: Grammar Challenge UI**
```
┌────────────────────────────────────┐
│  Correct the sentence:             │
│                                    │
│  "She don't like apples."          │ ← Editable text field
│                                    │
│  [                             ]   │ ← Input box
│                                    │
│  [Submit Answer] [Skip Card]       │ ← Clear action buttons
├────────────────────────────────────┤
│  Time: ██████████ 10s              │
└────────────────────────────────────┘
```

---

### Combat Screen Layout

```
┌─────────────────────────────────────────────────────────┐
│  Player HP: ████████░░ 78/100     Energy: ⚡⚡⚡        │
│  Relics: [📖][⚔️][🎓]            Curses: 2             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│            ENEMY: УТГАЛУ                                │
│            HP: ███████░░░ 28/40                         │
│            Intent: 🗡️ 7 dmg + 🌀 Confusion              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Hand: [Card1] [Card2] [Card3] [Card4] [Card5]         │
│        ↑ Hover for details                              │
├─────────────────────────────────────────────────────────┤
│  Draw Pile: 12  |  Discard: 5  |  [End Turn]           │
└─────────────────────────────────────────────────────────┘
```

**Key Features:**
- **Enemy Intent:** Always visible (no guessing)
- **Card Hover:** Shows full effect text + challenge type
- **Energy Display:** Clear visual (3/3 icons vs. just "3")
- **Status Effects:** Icons with tooltips on hover

---

### Map Screen Design

**Visual Style:** Branching tree of nodes, similar to Slay the Spire

```
         👑 BOSS
          |
    ⚔️──┬──❓──┬──💰
       |        |
    📚──┼──🔥──┼──⚔️
       |        |
    ⚔️──┴──❓──┴──⚔️
          |
         🎯 START
```

**Node Visuals:**
- **Combat:** Crossed swords (animated pulse)
- **Library:** Book with glow effect
- **Rest Site:** Campfire with flickering flame
- **Merchant:** Coin stack
- **Event:** Question mark with rotating animation
- **Boss:** Crown with ominous aura

**Interactivity:**
- Hover over node → Shows reward preview (e.g., "3 card choices")
- Completed nodes → Grayed out with checkmark

---

### Menu & Settings UI

**Main Menu:**
```
┌────────────────────────────┐
│      LEXICA SPIRE          │ ← Title in gothic font
│                            │
│  [▶ New Run]               │
│  [📊 Progress]             │
│  [⚙️ Settings]             │
│  [📘 Tutorial]             │
│  [❌ Exit]                 │
└────────────────────────────┘
```

**Settings Menu:**
- **Difficulty:** A1-C2 (adjusts vocabulary/grammar level)
- **Audio:** Music, SFX, Voice (separate sliders)
- **Accessibility:** Colorblind, Dyslexic Font, Text Size
- **Challenge Types:** Toggle speaking/listening challenges
- **Spaced Repetition:** ON/OFF (some players may want pure roguelike)

---

### Animation Guidelines

**Core Principle:** *Animations enhance, never delay gameplay.*

**Fast Animations (<0.5s):**
- Card draw
- Damage numbers popup
- Status effect icons appearing

**Medium Animations (0.5-1s):**
- Card played (slides to center, activates)
- Enemy attack (telegraphed but quick)
- Block shield shimmer

**Skippable Animations (>1s):**
- Boss entrance cutscene
- Relic acquisition fanfare
- Act transition

**Animation Polish:**
- **Juice:** Screen shake on big hits
- **Feedback:** Cards "bounce" when hovered
- **Personality:** Enemies have idle animations (breathing, fidgeting)

---

### Audio Design Notes

**Music:**
- **Style:** Orchestral + chiptune hybrid (Crypt of the NecroDancer meets Slay the Spire)
- **Act 1:** Curious, slightly tense (learning phase)
- **Act 2:** More urgent, complex instrumentation (mastery phase)
- **Act 3:** Epic, triumphant (challenge phase)
- **Boss Themes:** Unique leitmotif per boss

**SFX:**
- **Card Play:** Paper shuffle + magical "whoosh"
- **Correct Answer:** Pleasant "ding" (not annoying after 1000 times)
- **Incorrect Answer:** Subtle "buzz" (not punitive)
- **Perfect Answer:** Triumphant chime + sparkle
- **Damage Taken:** Thud + grunt (player)
- **Enemy Defeated:** Satisfying "crumble" sound

**Voice Acting (Optional):**
- Narrator for events (mysterious tutor voice)
- Boss dialogue (taunts about grammar mistakes)
- NO voice for challenges (text-to-speech is off-putting for learning)

---

## 🗓️ Development Roadmap

### Phase 1: MVP (3-4 Months)

**Goal:** Playable vertical slice with core loop validated.

#### Month 1: Foundation
**Week 1-2:**
- ✅ Set up Godot project structure
- ✅ Implement card system (data-driven JSON)
- ✅ Basic combat state machine (player turn → enemy turn)
- ✅ Simple UI (hand, deck, HP/Energy)

**Week 3-4:**
- ✅ Challenge system framework
  - Vocabulary challenge (multiple choice)
  - Grammar challenge (text input)
- ✅ Answer validation (backend API skeleton)
- ✅ Performance scoring (Perfect/Correct/Slow/Mistake)

---

#### Month 2: Core Content
**Week 5-6:**
- ✅ **20 Cards Implemented:**
  - 8 Common Attacks
  - 6 Common Skills
  - 4 Uncommon Attacks
  - 2 Uncommon Skills
- ✅ Card effects (damage, block, draw)
- ✅ Energy system

**Week 7-8:**
- ✅ **6 Enemy Types:**
  - Шёпот / Whisper (базовый дух)
  - Утгалу / Utgallu (средний дух, когти + дебаффы)
  - Одержимый раб (быстрые multi-hit атаки)
  - Одержимый стражник (танк, блок + сильные удары)
  - Одержимый жрец (кастер, проклятия + баффы)
  - Разорванный / The Torn (элитный)
- ✅ Enemy AI patterns
- ✅ Intent display system

---

#### Month 3: Boss & Progression
**Week 9-10:**
- ✅ **Act 1 Boss: Ашипу (Ashipu)**
  - Full implementation (250 HP, abilities, phases)
  - Temporal Shift mechanic
  - Ultimate phase challenge
- ✅ Map generation (15 nodes, procedural paths)

**Week 11-12:**
- ✅ **2 Curses Implemented:**
  - Echo of a Typo
  - Tense Fog
- ✅ Curse purification at Rest Sites
- ✅ Save/Load system (local JSON)

---

#### Month 4: Polish & Testing
**Week 13-14:**
- ✅ Balance pass (card costs, enemy HP, damage values)
- ✅ 5 Relics implemented
- ✅ Basic shop system (buy/remove cards)

**Week 15-16:**
- ✅ MVP Playtesting (10-20 external testers)
- ✅ Bug fixes from feedback
- ✅ Tutorial sequence (first 3 nodes)

**MVP Deliverable:**
- 20 cards, 3 enemies, 1 boss
- 1 full Act (15 nodes)
- Functional spaced repetition
- Playable from start to Act 1 boss defeat

---

### Phase 2: Alpha (2-3 Months)

**Goal:** Expand content, add meta-progression, refine balance.

#### Month 5: Act 2 Development
**Week 17-18:**
- ✅ **Act 2 Boss: The Idiom Sphinx**
  - Riddle-based mechanics
  - 300 HP, 4 phases
- ✅ 5 new enemy types (intermediate difficulty)

**Week 19-20:**
- ✅ **30 New Cards:**
  - 15 Common
  - 10 Uncommon
  - 5 Rare
- ✅ New card mechanics (multi-hit, conditional effects)

---

#### Month 6: Events & Economy
**Week 21-22:**
- ✅ **6 Random Events:**
  - Library of Forgotten Idioms
  - Slang Merchant
  - Mirror of True Self
  - Broken Gramophone
  - Curse Conversion
  - Linguistic Betting
- ✅ Event consequence system

**Week 23-24:**
- ✅ Expanded shop (Tutor services)
- ✅ Card transmutation event
- ✅ Dynamic pricing algorithm

---

#### Month 7: Meta-Progression
**Week 25-26:**
- ✅ **Insight Points System:**
  - Earned from Perfect Answers
  - Spent on unlocks between runs
- ✅ **Library of Mastery:**
  - Vocabulary tier unlocks
  - Grammar module unlocks
  - Mental Endurance upgrades

**Week 27-28:**
- ✅ 2 Alternate Starting Decks
- ✅ Achievement system (20 achievements)
- ✅ Alpha playtesting (50+ testers)

**Alpha Deliverable:**
- 50 cards, 8 enemies, 2 bosses
- 2 full Acts
- 6 events, expanded shop
- Meta-progression active

---

### Phase 3: Beta (2-3 Months)

**Goal:** Complete game, add polish, prepare for release.

#### Month 8: Act 3 & Final Boss
**Week 29-30:**
- ✅ **Act 3 Boss: The Polyglot Sovereign**
  - Multi-language mechanics (Easter egg: supports other languages)
  - 400 HP, ultimate challenge
- ✅ 5 new elite enemies

**Week 31-32:**
- ✅ **30 More Cards (Total: 80):**
  - Focus on build-around synergies
  - "Infinite" combo enablers
- ✅ Card upgrade system at Rest Sites

---

#### Month 9: Audio & Polish
**Week 33-34:**
- ✅ Music implementation (3 Act themes + 3 boss themes)
- ✅ SFX for all actions (150+ sounds)
- ✅ **Speech Recognition (Optional):**
  - Vosk integration for Echo challenges
  - Fallback: Skip speaking challenges

**Week 35-36:**
- ✅ Animation polish (juice, screen shake, particles)
- ✅ UI/UX refinement based on feedback
- ✅ Accessibility features (colorblind, dyslexic font)

---

#### Month 10: Balancing & Testing
**Week 37-38:**
- ✅ Full balance pass (targeting 20% win rate)
- ✅ Spaced repetition tuning
- ✅ Curse intensity algorithm testing

**Week 39-40:**
- ✅ Beta testing (200+ players)
- ✅ Bug fixing sprint
- ✅ Performance optimization (60 FPS on mid-range PCs)

**Beta Deliverable:**
- 80 cards, 15 enemies, 3 bosses
- 3 full Acts + true ending
- All systems polished and balanced
- Ready for launch

---

### Phase 4: Release (1-2 Months)

#### Month 11: Pre-Launch
**Week 41-42:**
- ✅ Steam store page setup (trailer, screenshots, description)
- ✅ Itch.io page setup
- ✅ Press kit (for gaming/education media)
- ✅ Launch trailer (2-3 minutes, showcases unique mechanics)

**Week 43-44:**
- ✅ Final QA pass
- ✅ Localization (Russian, Spanish, Chinese—UI only, challenges stay English)
- ✅ Steam achievements integration
- ✅ Cloud save setup

---

#### Month 12: Launch & Post-Launch
**Week 45:**
- 🚀 **Launch Day!**
  - Release on Steam Early Access + Itch.io
  - Price: $14.99 (10% launch discount → $13.49)
  - Post on Reddit (r/gamedev, r/languagelearning, r/roguelikes)
  - Submit to gaming sites (RockPaperShotgun, PCGamer education section)

**Week 46-48:**
- ✅ Hotfixes based on player feedback
- ✅ Balance patches (nerf overpowered cards)
- ✅ Community engagement (Discord server, Twitter)
- ✅ Post-launch content planning (Act 4? New languages?)

---

### Post-Release Roadmap (Optional Expansions)

#### **DLC Idea 1: "The Slang Expansion"**
- New Act focusing on colloquial English
- 20 new cards (idioms, phrasal verbs)
- Boss: The Meme Lord (internet slang)
- Release: 6 months post-launch

#### **DLC Idea 2: "Polyglot Mode"**
- Unlock Spanish, French, German learning modes
- New starting decks per language
- Cross-language challenges (translate between languages)
- Release: 12 months post-launch

#### **Free Updates:**
- Monthly card additions (2-3 per month)
- Seasonal events (Halloween: Spooky Vocabulary)
- Balance patches
- Community-requested features

---

### Development Team (Recommended)

**Minimum Viable Team:**
1. **Game Developer** (Godot/Unity)
2. **Backend Developer** (Python + NLP)
3. **Artist** (2D illustrator for cards/enemies)
4. **Sound Designer** (Music + SFX)
5. **Linguist/Educator** (Challenge design, balance)

**Ideal Team (+):**
- UI/UX Designer (dedicated)
- QA Tester (full-time during beta)
- Marketing/Community Manager

**Budget Estimate (Indie):**
- Development: $50k-$100k (salaries/contractors)
- Audio: $5k-$10k (music commission)
- Marketing: $5k-$15k (ads, influencer outreach)
- **Total:** $60k-$125k

**Break-Even Analysis:**
- Price: $15
- Steam cut: 30% → $10.50 per sale
- Break-even: 5,714-11,905 sales
- Realistic target: 20,000 sales in Year 1 ($210k revenue)

---

## 📊 Success Metrics & KPIs

### Educational Impact
- **Vocabulary Retention:** >70% after 30 days (measured by post-game quizzes)
- **Grammar Accuracy Improvement:** +25% from pre-test to post-test (per Act)
- **Spaced Repetition Effectiveness:** <15% mistake repetition rate

### Player Engagement
- **Average Session Length:** 35-50 minutes
- **Runs Per Player:** 15+ (indicating replayability)
- **Completion Rate:** 18-25% (standard for roguelikes)
- **Return Rate (7-day):** >50%

### Commercial Success
- **Sales Target (Year 1):** 20,000 copies
- **Review Score:** >85% positive (Steam)
- **Wishlist Conversions:** 25-30%

---

## 🎓 Design Philosophy Summary

### Core Tenets

1. **Learning IS Playing:** Challenges aren't interruptions—they ARE the combat
2. **Failure Teaches:** Every mistake becomes a personalized lesson (Curses)
3. **Respect Player Time:** Quick feedback, skippable animations, efficient tutorials
4. **Depth Through Simplicity:** Easy to learn, hard to master (like chess)
5. **Adaptive Challenge:** Game meets player at their level, always pushing growth

---

## 🔚 Conclusion

**Lexica Spire** represents a new paradigm in educational gaming: a game where learning English isn't a side activity or mini-game, but the core mechanic that drives all strategic decisions. By merging the proven roguelike formula with linguistically meaningful challenges, spaced repetition algorithms, and meaningful failure states, the game offers both deep strategic gameplay and measurable educational outcomes.

The development roadmap is ambitious but achievable with a focused team and iterative approach. The MVP phase validates the core loop, Alpha expands content and systems, Beta polishes and balances, and Release brings the vision to players worldwide.

**Next Steps:**
1. Assemble core development team
2. Build MVP combat prototype (Month 1-2)
3. Playtest with language learners (Month 3)
4. Iterate based on feedback
5. Scale content and systems toward Alpha/Beta

---

**Document Version:** 1.0
**Last Updated:** February 13, 2026
**Status:** Ready for Development

---

*"Every word you master is a weapon. Every mistake, a lesson. Climb the Lexica Spire."*
