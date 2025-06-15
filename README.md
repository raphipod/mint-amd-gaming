# mint-amd-gaming
Small shell script to prepare stock Linux Mint for gaming (AMD GPU's only!)

Please ALWAYS inspect the script before you execute it, it might do things you don't want it to do!

## What does it do?

- installs the XanMod Main/stable kernel (better GPU/CPU support, newer features)
- installs Kisak-mesa by default (better GPU support)
- activates FreeSync and TearFree in X11 for better multi-monitor support and VRR (AMD GPUs newer than GCN1 & X11 only)

I will probably add more stuff soon -  I really want to add LACT for better under-/overclocking and maybe handle installing Steam and/or Heroic
while I am at it. For now, I've just written down what I had in my head for a few days - just fixes for Mint for Gaming.
And yes, I know that Mint will switch to Wayland at some point in the future, but it won't be a default for a few main releases of LM.

## Usage:

Make it executable with `chmod +x ./mint-gaming-setup.sh`, then:

`sudo ./mint-gaming-setup.sh` [--mesa oibaf|kisak]

(Yes, you can choose between different Mesa sources. Kisak is used by default,
so if you want to use oibaf, you must add `--mesa oibaf` after the command.)

