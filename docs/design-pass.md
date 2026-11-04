# Star Paris — UI/UX Redesign Pass

Written against the state of the code before the per-screen pass. This is the
senior-designer read: what is wrong, what the design language is, and what
changes, in order. The foundation (tokens, motion, components) lands first;
screens follow the moment the Quick Sale feature is merged so nothing races.

## 1. Diagnosis — what a designer sees first

The app is competent but flat. It reads as "functional", not "product", for
five specific reasons:

1. **No elevation ramp.** Every card sits at elevation 0 with a hairline border.
   The eye has no figure/ground: a dashboard tile, a dialog and a list row all
   have the same visual weight. There is nothing that says "this is above that".
2. **No interaction feedback.** The app is used with a mouse on Windows, but
   nothing lifts on hover, presses on click, or animates on change. A desktop
   app that doesn't respond to the pointer feels dead, even when every button
   works.
3. **The numbers don't breathe.** The Today figures (the four "doors") are the
   single most important surface, and they update instantly with no motion. A
   counter clerk should *feel* a job move to done.
4. **One type size for everything big.** `headlineSmall` is the ceiling, so the
   greeting, a figure, and a section title all compete in the same band.
5. **Glass is promised but absent.** The design says glass on the top bar and
   side panel; today they are flat surfaces. One `GlassPanel` component makes
   that real without blurring content the clerk must read.

## 2. Design language — five pillars

- **Calm hierarchy.** Page → section → row, always, and only the figures may
  shout. Type, not colour, does the ranking; colour is reserved for status.
- **Ink on paper.** Deep petrol (ink) and warm sand (paper) — a print shop's own
  palette — with an ember accent that appears only for rush, overdue and money
  owed. Status is always colour + icon + word.
- **Motion with a job.** Motion announces change (a figure counts up, a card
  lifts when the pointer is on it, a page fades in). It never decorates, and it
  always respects reduce-motion.
- **Glass where it costs nothing.** The top bar and side panel blur what scrolls
  beneath them; content surfaces stay opaque so a clerk never reads through a
  haze.
- **Density that matches the hand.** Compact on a mouse, comfortable on a thumb.
  One theme, two densities, no per-screen pixel tuning.

## 3. Foundation (this pass, additive — lands before screens)

Tokens (`tokens.dart`):

- `StarMotion` — named durations and curves (`instant`, `fast` 160 ms,
  `standard` 240 ms, `slow` 360 ms; `easeOut`, `easeInOut`). One place to tune
  the whole app's feel.
- A surface ramp (`surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`,
  an `ink` text colour) so elevation reads even on a flat background.

Theme (`theme.dart`):

- A **display scale**: `displayLarge/Medium/Small` sized for the figures and the
  greeting, tabular figures so a changing number doesn't jitter the layout.
- Dialogs and bottom sheets on `surfaceContainerHighest` with the card radius —
  raised, distinct from the page behind them.

Components (`lib/src/widgets/`, each exported + widget-tested):

- `PressableCard` — hover lift + pressed settle + ink ripple; the one widget
  every tappable tile, stat and list card migrates to.
- `AnimatedCount` — a figure that counts from its previous value to the new one
  in one motion curve; instant under reduce-motion. For the Today figures.
- `GlassPanel` — a translucent, blurred panel with a solid fallback colour when
  blur is disabled or too costly.
- `ShortcutChip` — a small key-cap (`Ctrl K`, `F5`) for the top bar so a
  shortcut is visible, not discoverable-by-accident.

## 4. Per-surface plan (next pass, after Quick Sale merges)

Ordered by impact:

1. **Shell.** Apply `GlassPanel` to the top bar and side panel; `ShortcutChip`s
   beside the search field; hover states on every rail item (already hand-rolled —
   add the PressableCard treatment). Confirm the counted-index rule still holds
   after Quick Sale adds the POS destination.
2. **Today (home).** Figures become `AnimatedCount` inside `PressableCard`s;
   the display scale sizes them; tiles lift on hover so "this is a door" is
   obvious before the click.
3. **Board / production.** Cards become `PressableCard`s; a stage column that is
   over-capacity gets a subtle ember wash (colour + a count word, never colour
   alone). Drag targets get a hover outline.
4. **Order builder.** The live price bar uses `AnimatedCount` so a tap on a size
   or finish visibly reprices. The summary column gets the display scale.
5. **Lists (customers, orders, staff, vendors).** Rows adopt the PressableCard
   hover; empty states already say what appears and when — keep that.

## 5. Accessibility and honesty

- Every animation guards `MediaQuery.disableAnimations` (reduce-motion).
- Status stays colour + icon + text; variance and lateness carry the word.
- After the pass: `flutter analyze`, widget tests per new component, `flutter
  test`, a release build — and the honest statement that it has not been
  click-tested on hardware and the visual judgment is the client's.

## 6. Arabic

Mirroring is already wired (locale switch, directional spacing). Translation of
the full string catalogue is a separate decision (client vocabulary) and is not
part of this pass. Documents remain English (ADR-009) until a shaping-capable
renderer is chosen.
