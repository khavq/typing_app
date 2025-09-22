export default {
  mounted() {
    // Focus the input element when it's mounted
    this.el.focus()

    // Re-focus when element receives updates
    this.handleEvent("phx:update", () => {
      // Use setTimeout to ensure DOM is fully updated
      setTimeout(() => this.el.focus(), 10)
    })
  },

  updated() {
    // Re-focus the input when it's updated
    this.el.focus()
  }
}
