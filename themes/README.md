# Dashboard themes

Select a theme in your local `config.yaml`:

```yaml
default:
  theme_file: "themes/default.yml"
```

The shared `config-template.yaml` already selects this neutral colourway.
To create your own, copy `themes/default.yml` with any filename, then set
`theme_file` to that path. There is no requirement to name it `_brand.yml`:
the dashboard passes the configured path directly to bslib.

Paths resolve relative to the settings file, including when you pass
`run_app(config_file = "/another/location/config.yaml")`. Absolute paths and
`~` work too. Profiles inherit the default theme and can override it.
Set `theme_file: null` to use Bootstrap defaults without brand discovery.
A configured theme file must exist and be readable; invalid brand YAML is
reported when the interface renders. Restart the app after changing it.

Change the named palette colours and their semantic roles (`primary`, `success`,
`warning`, etc.). Quote hex values so YAML does not treat them as comments.
Keep text and links readable against their backgrounds. The title bar uses
`primary`, with automatically contrasting text. Fonts and logos are optional;
the example uses system fonts and no external assets.
The sidebar and section headers use Bootstrap's subtle primary colour; project
names and borders use primary accents, and assessment badges use secondary.
These styles use bslib theme settings and Bootstrap utilities, so they follow
any selected colourway without custom colour CSS.

Organisation-specific themes should stay local. `themes/Teck.yml` and
`config.yaml` are ignored by Git; add any other private theme filenames to
`.gitignore` before using them. Do not force-add local branding. The shared
`default.yml` and this guide can be committed. The `themes/` directory is excluded
from R package builds, so installed-package users must supply a theme file
alongside their settings or select `theme_file: null`. Install dependencies
with `rv sync`.

See [bslib's brand.yml guide](https://rstudio.github.io/bslib/articles/brand-yml/index.html)
for the full format.
