# Rivers Arcade

A collection of browser games. Play at: https://hjr-lab.github.io/arcade/

## Adding a New Game

1. Create a folder in `games/` (e.g., `games/my-new-game/`)
2. Add an `index.html` inside it
3. Optionally add a `game.json` for custom name/description:
   ```json
   { "name": "My Game", "description": "A fun game" }
   ```
4. Push — the menu updates automatically via GitHub Actions

### Back-to-arcade button

Every game includes a shared "back to the arcade" button. Add this just before
`</body>` in the game's `index.html`:

```html
<script src="../../arcade-home.js" data-corner="top-left"></script>
```

The link target is derived from the script's own path, so it works at any
folder depth. Optional attributes:

- `data-corner` — `top-left` (default), `top-right`, `bottom-left`, `bottom-right`.
  Pick a corner the game's own HUD doesn't use.
- `data-label` — button text (default `ARCADE`).
- `data-hide-on-touch="true"` — hide it on touch devices, for games with
  on-screen controls in the corners.

## Games

- **Flappy Bird v4** — Navigate the bird through pipes
- **Elemental Clash** — Elemental combat game
- **Market Watch** — Personal investing dashboard
