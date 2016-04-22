## [0.14.1]
- Enable autocompletion if there is no .tern-project file
- Try to restart the server if there was an uncaught exception in our child process

## [0.14]
- Update tern to 0.18.0
- Tern server now running in a node environment
- Fix keybindings could not be disabled via the package settings
- Rename now groups changes per file so you don't have to undo every single change

## [0.13]
- Push the tern server to a webworker
- Do not send files to the tern server if it is defined in dontLoad
- tern-lint is now disabled by default. Activate it via the package options
- Notify the user if no reference was found
- Optimize string completion
- Do not resolve tern dependency via git:// anymore
- various bugfixing

## [0.11.4]
- Added inline documentation with an overlay decoration. Use <kbd>alt-o</kbd> and get the documentation (if any) for the thing under the cursor.
- Some improvements how files get registered and updated. This should produce less errors and a better compatibility for projects not using the `loadEagerly` property and projects without a `.tern-project` file.
- Updated `npm-shrinkwrap` to use `https://` instead of `git://`. This hopefully fixes the behind proxy issues if only `http://` and `https://` is allowed.
- All decorations now have a max-width and should behave better if there is too much content.

## [0.11.0]
- Removed `autocomplete-snippets` as a default. By default method completion now won't add snippets after confirming the suggestion. Re-activate it via package settings.
- Removed the option `do not add parantheses`
- Some performance improvements
  - Do not update the file if there are no changes made to the text-buffer
  - Reduce garbage in certain contexes
- Updated Tern to the latest version
- Added the context menu items (find definition, find references & rename) to sub-menu
- Bugfixing

## [0.10.3]
- Updated Tern to the latest version
- Fixed keybindings for platform linux (see README.md)
- Added option to display suggestions above snippets
- Do not use shadowRoot to get `.scroll-view` if shadow DOM is disabled
- Bugfixing

## [0.8.0]
- Add support for ES6

## [0.5.24]
- Add support for multiply projects

## [0.4.13]
- TypeView to display completions for fn-params

## [0.4.6]
- Documentation now provides urls and origin
- Various improvements and bugfixing

## [0.4.4]
- Improved decision if completion should be triggered

## [0.4.2]
- Documentation is now being displayed via a panel
- Various bugfixing

## [0.4.0]
- Implemented feature: Find references

## [0.3.8]
- Package now works on Windows platform

## [0.0.1] - First Release
- First working example
