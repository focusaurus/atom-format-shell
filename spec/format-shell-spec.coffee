formatShell = require('..')
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe 'Format Shell', ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('format-shell')

    waitsForPromise ->
      atom.workspace.open()

  it 'converts', ->
    editor = atom.workspace.getActiveTextEditor()
    editor.insertText('testFunc()  {\necho foo  foo2\n    echo bar\n\n\n}')
    changeHandler = jasmine.createSpy('changeHandler')
    editor.onDidChange(changeHandler)

    atom.commands.dispatch workspaceElement, 'format-shell:format'

    waitsForPromise ->
      activationPromise

    waitsFor ->
      changeHandler.callCount > 0

    runs ->
      expect(editor.getText()).toEqual """testFunc() {
  echo foo foo2
  echo bar

}
"""
