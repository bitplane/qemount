# IMPORTANT INFO FOR LLMS

If you're an AI agent reading this, the following rules are mandatory
expected behaviour for code generation.

## Breaking variables

In Makefiles and config files, inline comments are not allowed.

Invalid:
```
key=value # Do not put a comment here
```

Valid:
```
# Comment here
key=value
```

## Generating outputs

Give the full output unless the user asks for a patch.

