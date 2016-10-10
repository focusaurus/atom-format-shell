'use babel'

import { CompositeDisposable } from 'atom'
const path = require('path')
import childProcess from 'child_process'

function isShellEditor (editor) {
  return path.extname(editor && editor.getPath() || '') === '.sh'
}

export default {
  subscriptions: null,

  activate (state) {
    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable()

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'format-shell:format': () => this.format()
    }))
  },

  deactivate () {
    this.subscriptions.dispose()
  },

  showError (message) {
    if (atom.config.get('format-shell.showErrorNotifications')) {
      atom.notifications.addError(message)
    }
  },

  showSuccess (message) {
    if (atom.config.get('format-shell.showNotifications')) {
      atom.notifications.addSuccess(message)
    }
  },

  format () {
    const editor = atom.workspace.getActiveTextEditor()
    if (!isShellEditor(editor)) {
      atom.notifications.addInfo('Not a shell script', {
        dismissable: false,
        detail: 'I only know how to format .sh files, sorry!'
      })
      return
    }
    const shfmtPath = atom.config.get('format-shell.shfmtPath')
    const indent = atom.config.get('format-shell.indent')
    const args = ['-i', indent]
    const options = {input: editor.getText()}
    try {
      const {status, stdout, stderr} = childProcess.spawnSync(shfmtPath, args, options)
      if (status == null) {
        this.showError(`format-shell could not find shfmt executable at ${shfmtPath}.\nPlease adjust the shell-format package settings.`)
        return
      }
      if (status > 0) {
        this.showError(`format-shell failed with code ${status}.\n${stderr.toString()}`)
        return
      }
      const cursorPosition = editor.getCursorScreenPosition()
      editor.buffer.setTextViaDiff(stdout.toString())
      editor.setCursorScreenPosition(cursorPosition)
      this.showSuccess('Formatted file')
    } catch (exception) {
      this.error(`format-shell exception: ${exception}`)
    }
  }

}
