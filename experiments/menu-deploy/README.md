# Menu deploy animation (WIP)

Experimental GTK companion for restarting Amber Strata's popover animation on
every map/unmap cycle without forking Ghostty.

Build and launch a disposable test window:

```sh
gcc -shared -fPIC -O2 -Wall -Wextra \
  -o /tmp/libstrata-popover-hook.so strata-popover-hook.c -ldl
LD_PRELOAD=/tmp/libstrata-popover-hook.so ghostty
```

Current state:

- repeat trigger works through GTK `map` and `unmap` emission hooks;
- the panel deployment and delayed content fade are deliberately slowed down;
- line and panel geometry still need refinement;
- diagnostic logging must be removed before this is production-ready;
- the companion is optional and is not installed by the main theme installer.

