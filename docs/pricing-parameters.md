# Pricing parameters a print shop actually needs

A catalogue of every input that moves the price of a print job, gathered from how commercial
estimating is described by practitioners (PIA/GATF cost-model literature, print ERP estimating
documentation, UK and UAE trade shops) and mapped onto what this system already stores. The point is
not to implement all of it — it is to know what "complete" looks like before adding a field nobody uses.

Legend: **HAVE** = stored and priced today · **ADD** = field exists in the schema, needs to reach the
catalogue editor · **NEW** = not in the system at all.

---

## 1. What the counter is asked

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Quantity | pcs | HAVE | Presets are data (`quantity_presets_json`) |
| Finished size | mm W×H | HAVE | Per-size list is data (`sizes_json`) |
| Flat size (pre-fold) | mm | NEW | A folding job has two sizes; only one is stored |
| Sides printed | 1 / 2 | HAVE | `sides` |
| Ink coverage | light / medium / heavy, or % | NEW | Drives ink cost and press speed on offset |
| Colour | 4/4, 4/0, 1/1, Pantone n | NEW | Spot colours are a charge, not a nuance |
| Substrate | material code | HAVE | `material_code` |
| Finishing operations | list | HAVE | `finishes_json` + rules |
| Delivery vs collection | enum | HAVE | `delivery_method` |
| Deadline / rush | % or days | HAVE | Rush as a percentage of price |
| Artwork supplied? | bool | NEW | Design time is billable when it is not |

## 2. Imposition and layout — where the money hides

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Parent sheet | mm W×H | HAVE | On the material and the product |
| Bleed | mm | HAVE | Default 3 mm |
| Gutter | mm | HAVE | Default 3 mm |
| Rotation allowed | bool | HAVE | Engine tries both orientations |
| Up-count | pcs/sheet | HAVE | Computed, stored in the breakdown |
| Grain direction | bool | NEW | A cross-grain fold cracks; some jobs cannot rotate |
| Gripper / non-print margin | mm | NEW | Real press sheets lose 8–12 mm on one edge |
| Trim allowance | mm | NEW | Guillotine creep on thick stacks |

## 3. Substrate

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Grade / type | text, art card, board, kraft, vinyl, board | HAVE (`type`) | |
| GSM | g/m² | HAVE | 130–400 for paper and card |
| Thickness | micron | NEW | Vinyl, flex, sunboard are sold by micron, not GSM |
| Sheet or roll width | mm | HAVE (sheet) / NEW (roll) | Roll width decides trim loss on banners |
| Cost basis | per sheet / per kg / per m² | HAVE (sheet) | Paper is bought per kg or per 1000 sheets |
| Cost | fils | HAVE | `cost_per_sheet_fils` |
| Supplier | ref | HAVE (`supplier_id`) | Unused today; needed for vendor cost drift |
| Stocked / on order | enum | NEW | Quoting stock you cannot buy is how jobs die |

Industry note: a text weight and a cover weight of the same size can differ by more than double per
sheet, which is why paper is priced per sheet rather than per job.

## 4. Waste and spoilage — planned, not discovered

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Makeready sheets | sheets | HAVE (`setup_sheets`, default 2) | Fixed per setup |
| Running spoilage | bps | HAVE (`spoilage_bps`) | 3–5 % digital, 5–8 % offset is the usual planning figure |
| Finishing waste | % | NEW | Each fold/cut pass loses sheets |
| Plate/die waste | pcs | NEW | Die-cut blanks lost to register |
| Reprint allowance | % | NEW | Bought deliberately on rush work |

Makeready is roughly fixed per setup while run spoilage scales with quantity — the estimate must add
both, and purchasing must buy against that figure, not the net sheet count.

## 5. Press and machine

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Press type | offset / digital / large-format | NEW | Changes the whole cost model |
| Machine hour rate (BHR) | fils/hour | NEW | The single number every cost model is built on |
| Setup / makeready time | minutes | NEW | Scales with colours and stock |
| Run speed | sheets/hour | NEW | Depends on machine, stock and coverage |
| Plate cost | fils/plate | NEW | Offset only; one per colour per side |
| Click charge | fils/impression | NEW | Digital only; often includes toner |
| Ink / toner cost | fils per m² at coverage | NEW | |
| Drying / curing time | minutes | NEW | Blocks the schedule more than the price |

The standard estimating formula is `cost = production time × BHR + consumables + buy-outs`.

## 6. Finishing operations

Each of these is its own setup + run rate, which is why they must be rows in an operations catalogue
rather than a percentage.

| Operation | Typical basis | State |
|---|---|---|
| Lamination — gloss / matt / soft-touch / anti-scratch | per side, per m² or per 1000 | HAVE (matt and gloss rules; soft-touch and anti-scratch **ADD**) |
| Varnish — inline UV, aqueous, spot UV, sand UV | per sheet, or per spot area | HAVE (partial) — spot UV **NEW** |
| Foil stamping | setup (die) + per 1000 | **NEW** |
| Embossing / debossing | setup (die) + per 1000 | **NEW** |
| Die cutting / laser cutting | die cost amortised + per 1000 | **NEW** |
| Creasing / scoring | per 1000 + setup | HAVE (rule form) |
| Perforation | per 1000 | **NEW** |
| Folding — bi-fold, tri-fold, gate, accordion | per 1000 + setup | **NEW** |
| Binding — saddle stitch, perfect, wire-o, spiral, sewn | per copy + setup | **NEW** |
| Padding / numbering / drilling | per pad / per 1000 | **NEW** |
| Rounded corners | per 1000 | **NEW** |
| Shrink wrap, encapsulation | per copy | **NEW** |
| Mounting on foam board | per m² | **NEW** |
| Banner finishing — hem, eyelets, pole pocket, velcro | per metre | **NEW** |

## 7. Large format — a different arithmetic

Priced by the square metre, then adjusted:

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Area rate | fils/m² | HAVE (`area_rate_fils_per_sqm`) | |
| Roll width / trim loss | % | NEW | Optimising deckle saves real money |
| Panel division | count | NEW | A 14 m banner is several panels plus overlaps |
| UV / weather life | years | NEW | Cheap stock fails in a UAE summer |
| Fire-retardant certificate | bool | **NEW** | Required for many municipal sites |
| Installation / rigging | fils | NEW | Quoted separately, priced on height and access |
| Permit coordination | fils | NEW | Dubai Municipality caps hoarding height at 3.0 m |

Typical UAE market rates for context (ex-VAT, 2026): frontlit PVC 510 gsm AED 18–28/m², micro-mesh
340 gsm AED 22–35/m², backlit flex 650 gsm AED 30–48/m²; 500+ m² attracts 15–20 % off.

## 8. Labour and prepress

| Parameter | Unit | State |
|---|---|---|
| Design time | hours × rate | **NEW** |
| Artwork prep / preflight | hours | **NEW** |
| Proofing / plate making | per plate / per proof | **NEW** |
| Finishing labour | hours | **NEW** |
| Delivery / driver | per trip or per zone | **NEW** |

## 9. Commercial

| Parameter | Unit | State | Notes |
|---|---|---|---|
| Markup / margin | bps | HAVE | Owner-controlled |
| Minimum order / minimum charge | fils | HAVE | |
| Rounding step | fils | HAVE | One rule, applied at the end |
| Rush surcharge | % | HAVE | UAE shops commonly add 50 % for same-day |
| Discount | % | HAVE | |
| Volume breaks | tiers | **NEW** | 100/500/1000 priced side by side is what customers ask for |
| Deposit / advance | % | **NEW** | Standard in this trade |
| Credit terms | days | HAVE (customer) | |
| VAT | bps | HAVE (settings) | 5 % UAE |
| Vendor cost / commission | fils | HAVE (vendor jobs) | Margin = order total − vendor cost |
| Currency | AED | implicit | |

## 10. Customer and job metadata that affects price

| Parameter | State |
|---|---|
| Customer tier (retail / trade / corporate) | HAVE (`tier`) — not yet used in pricing |
| Credit limit and terms | HAVE — not enforced at order time |
| WhatsApp opt-in | HAVE |
| Repeat / standing order | **NEW** |
| Job history (same artwork reprinted) | **NEW** — a reprint should be cheaper |

---

## What this means for the build

Three additions unlock most of the list, and none of them are exotic:

1. **Machines** — name, type, hourly rate, setup minutes, run speed, plate/click cost. This turns the
   current cost-plus engine into a real cost model and is the biggest single gap.
2. **An operations catalogue** — one row per finishing operation with its basis (per 1000, per side,
   per m², per copy), setup charge and waste. Today each operation exists as a bespoke rule; the
   catalogue makes "add foil stamping" a data entry, not a deployment.
3. **Quantity breaks and customer tier** — price 100/500/1000 at once, and let trade customers see
   trade rates. The fields for tier already exist and are unused.

After those, the catalogue editor (materials with GSM and thickness, products, rules, option lists)
is the surface that makes all of it the owner's, not the developer's.
