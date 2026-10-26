# flutter_alone

A Flutter desktop plugin that keeps an app to one running copy on Windows, macOS and Linux.

## Language

**Running instance**:
The app process that holds the single-instance lock.
_Avoid_: Owner, holder, existing instance, first instance

**Duplicate launch**:
A launch of the same app that starts while a running instance exists and is refused.
_Avoid_: Second launch, second instance, duplicate instance
