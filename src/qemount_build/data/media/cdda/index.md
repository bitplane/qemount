---
format: media/cdda
requires:
  - docker:builder/disk/debian
provides:
  - data/media/talking.cdda
---

# CDDA Audio Track

Raw CDDA audio track generated using espeak-ng text-to-speech.

Contains the Stephen Hawking quote from Pink Floyd's "Keep Talking":

> For millions of years, mankind lived just like the animals. Then something
> happened, which unleashed the power of our imagination. We learned to talk.

Output is raw 16-bit stereo PCM at 44.1kHz, little-endian - the standard
Red Book CD audio format.
